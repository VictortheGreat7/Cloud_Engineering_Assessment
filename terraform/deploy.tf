# This file is responsible for deploying the time API application to the Azure Kubernetes Service (AKS) cluster.

# This module deploys the NGINX Ingress Controller to the Kubernetes cluster.
# It provides a way to expose HTTP and HTTPS routes from outside the cluster to the appropriate service based on the defined rules.
module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = ">=2.3.0"

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.17.1"

  create_namespace = true
  namespace        = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [module.nginx-controller]
}

resource "time_sleep" "wait" {
  create_duration = "30s"

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "cert-manager-issuers" {
  chart      = "cert-manager-issuers"
  name       = "cert-manager-issuers"
  version    = "0.3.0"
  repository = "https://charts.adfinis.com"

  values = [<<-YAML
  clusterIssuers:
    - name: certmanager
      spec:
        acme:
          email: "greatvictor.anjorin@gmail.com"
          server: "https://acme-v02.api.letsencrypt.org/directory"
          privateKeySecretRef:
            name: certmanager
          solvers:
            - dns01:
                azureDNS:
                  resourceGroupName: "${azurerm_dns_zone.mywonder_works.resource_group_name}"
                  subscriptionID: "d31507f4-324c-4bd1-abe1-5cdf45cba77d"
                  hostedZoneName: "${azurerm_dns_zone.mywonder_works.name}"
                  environment: AzurePublicCloud
                  managedIdentity:
                    clientID: "${data.azurerm_kubernetes_cluster.time_api_cluster.kubelet_identity[0].object_id}"
YAML
  ]

  depends_on = [helm_release.cert_manager, time_sleep.wait]
}

# This resource creates a ConfigMap in the Kubernetes cluster.
# A ConfigMap is used to store non-confidential data in key-value pairs.
# ConfigMaps are used to decouple environment-specific configuration from the container images, allowing for more flexible deployments.
# The time zone is set to UTC, but this can be changed as needed.
resource "kubernetes_config_map" "time_api_config" {
  metadata {
    name = "time-api-config"
  }

  data = {
    TIME_ZONE = "UTC"
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# This deploys the time API application to the Kubernetes cluster
resource "kubernetes_deployment" "time_api" {
  metadata {
    name = "time-api"
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

  depends_on = [kubernetes_config_map.time_api_config]
}

# This creates a service for the time API deployment, allowing it to be accessed within the cluster.
# The service is of type ClusterIP, which means it will only be accessible from within the cluster.
resource "kubernetes_service" "time_api" {
  metadata {
    name = "time-api-service"
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

  depends_on = [kubernetes_deployment.time_api]
}

# This gives the time API service an external IP address and makes it accessible from outside the cluster.
resource "kubernetes_ingress_v1" "time_api" {
  metadata {
    name = "time-api-ingress"
    annotations = {
      "cert-manager.io/cluster-issuer"           = "certmanager"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
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
              name = kubernetes_service.time_api.metadata[0].name
              port {
                number = kubernetes_service.time_api.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.time_api, helm_release.cert-manager-issuers]
}

# This tests the time API by sending 50 requests to the service and checking if the response is successful.
# It's a simple load test to ensure the service is up and running.
resource "kubernetes_job" "time_api_loadtest" {
  metadata {
    name = "time-api-loadtest"
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
              wget -q -O- http://time-api-service.default.svc.cluster.local:80/time && 
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

  depends_on = [kubernetes_service.time_api, kubernetes_ingress_v1.time_api]

  timeouts {
    create = "5m"
  }
}
