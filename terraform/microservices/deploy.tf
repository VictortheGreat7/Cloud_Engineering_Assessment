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

  depends_on = [module.nginx-controller, helm_release.cert_manager_issuers, kubernetes_namespace_v1.time_api]
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

resource "time_sleep" "wait_for_nginx" {
  create_duration = "120s"  # Wait 2 minutes

  depends_on = [module.nginx-controller]
}

# This makes the API service accessible from outside the cluster.
resource "kubernetes_ingress_v1" "time_api" {
  metadata {
    name      = "time-api-ingress"
    namespace = "time-api"
    annotations = {
      "cert-manager.io/cluster-issuer" = "certmanager"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["api.mywonder.works"]
      secret_name = "time-api-tls"
    }

    rule {
      host = "api.mywonder.works"
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

  depends_on = [kubernetes_service_v1.time_api, time_sleep.wait_for_nginx]
}
