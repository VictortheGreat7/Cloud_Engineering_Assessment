# This script defines the instructions for the deployment of the time API microservice to the Azure Kubernetes Service (AKS) cluster.

# This deploys the time API microservice to the Kubernetes cluster
resource "kubernetes_deployment_v1" "time_api" {
  metadata {
    name      = "time-api"
    namespace = "time-api"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "time-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "time-api"
        }
      }

      spec {
        container {
          name  = "time-api"
          image = "victorthegreat7/time-api:latest"

          port {
            container_port = 5000
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [module.nginx-controller, kubernetes_namespace_v1.time_api]
}

# This creates a service for the time API deployment, allowing it to be accessed within the cluster.
resource "kubernetes_service_v1" "time_api" {
  metadata {
    name      = "time-api-service"
    namespace = "time-api"
  }

  spec {
    selector = {
      app = "time-api"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 5000
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.time_api]
}

# This tests the time API by sending 50 requests to the service and checking if the response is successful.
resource "kubernetes_job_v1" "time_api_loadtest" {
  metadata {
    name      = "time-api-loadtest"
    namespace = "time-api"
  }

  spec {
    template {
      metadata {
        name = "time-api-loadtest"
      }
      spec {
        container {
          name    = "loadtest"
          image   = "busybox"
          command = ["/bin/sh", "-c"]
          args = [<<-EOF
            for i in $(seq 1 50); do 
              wget -q -O- http://time-api-service.time-api.svc.cluster.local:80/time && 
              echo "Request $i successful"; 
              sleep 0.1; 
            done
          EOF
          ]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit           = 4
    active_deadline_seconds = 300
  }

  depends_on = [kubernetes_service_v1.time_api]
}

resource "null_resource" "wait_for_ingress_webhook" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e

      echo "Getting AKS credentials..."
      az aks get-credentials --resource-group "${azurerm_kubernetes_cluster.time_api_cluster.resource_group_name}" --name "${azurerm_kubernetes_cluster.time_api_cluster.name}" --overwrite-existing

      echo "Installing kubelogin..."
      sudo az aks install-cli

      echo "Converting kubeconfig with kubelogin..."
      kubelogin convert-kubeconfig -l azurecli

      echo "Waiting for ingress-nginx-controller DaemonSet pods to be ready..."
      for i in {1..100}; do
        READY=$(kubectl get daemonset ingress-nginx-controller -n kube-system -o jsonpath='{.status.numberReady}')
  
        echo "Attempt $i: $READY pods ready"

        if [[ "$READY" -ge 1 ]]; then
          echo "At least one DaemonSet pod is ready"
          break
        fi

        if [[ "$i" -eq 100 ]]; then
          echo "Timed out waiting for at least one DaemonSet pod to be ready"
          exit 1
        fi

        sleep 10
      done


      echo "Waiting for admission webhook to be ready..."
      for i in {1..100}; do
        echo "Checking webhook readiness... attempt $i"
        if kubectl get endpoints ingress-nginx-controller-admission -n kube-system -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; then
          echo "Webhook server is ready"
          exit 0
        fi
        sleep 10
      done

      echo "Timed out waiting for ingress-nginx admission webhook"
      exit 1
    EOT
  }

  depends_on = [module.nginx-controller]
}

resource "kubernetes_job_v1" "wait_for_ingress_webhook" {
  metadata {
    name      = "check-ingress-webhook"
    namespace = "kube-system"
  }

  spec {
    template {
      metadata {
        name = "ingress-webhook-test"
      }
      spec {
        container {
          name    = "check"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/bash", "-c"]
          args = [
            <<-EOC
            for i in {1..100}; do
              echo "Checking for webhook admission endpoint..."
              IP=$(kubectl get endpoints ingress-nginx-controller-admission -n kube-system -o jsonpath='{.subsets[*].addresses[*].ip}')
              if [[ ! -z "$IP" ]]; then
                echo "Admission webhook is ready"
                exit 0
              fi
              echo "Attempt $i: Admission webhook not ready yet"
              sleep 10
            done
            echo "Timed out waiting for admission webhook"
            exit 1
            EOC
          ]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit           = 4
    active_deadline_seconds = 2000
  }

  depends_on = [null_resource.wait_for_ingress_webhook]
}



# This makes the API service accessible from outside the cluster.
resource "kubernetes_ingress_v1" "time_api" {
  metadata {
    name      = "time-api-ingress"
    namespace = "time-api"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/time"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.time_api.metadata[0].name
              port {
                number = kubernetes_service_v1.time_api.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.time_api, azurerm_dashboard_grafana.timeapi_grafana, null_resource.wait_for_ingress_webhook, kubernetes_job_v1.wait_for_ingress_webhook]
}
