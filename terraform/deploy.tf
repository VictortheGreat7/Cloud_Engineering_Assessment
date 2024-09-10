resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  depends_on = [azurerm_kubernetes_cluster.capstone]
}

module "cert_manager" {
  source = "terraform-iaac/cert-manager/kubernetes"

  cluster_issuer_email                   = "greatvictor.anjorin@gmail.com"
  cluster_issuer_name                    = "letsencrypt-cluster-issuer"
  cluster_issuer_private_key_secret_name = "letsencrypt-cluster-issuer-key"

  solvers = [
    {
      http01 = {
        ingress = {
          class = "nginx"
        }
      }
    }
  ]

  # certificates = {
  #   "my_certificate" = {
  #     dns_names = ["api.mywonder.works"]
  #   }
}

# Time API ConfigMap
resource "kubernetes_config_map" "time_api_config" {
  metadata {
    name = "time-api-config"
  }

  data = {
    TIME_ZONE = "UTC"
  }

  depends_on = [azurerm_kubernetes_cluster.capstone, helm_release.nginx_ingress, module.cert_manager]
}

# Time API Deployment
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

          env {
            name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
            value = azurerm_application_insights.api.instrumentation_key
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

  depends_on = [kubernetes_config_map.time_api_config, azurerm_kubernetes_cluster.capstone]
}

# Time API Service
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

  depends_on = [kubernetes_deployment.time_api, azurerm_kubernetes_cluster.capstone]
}

# # ClusterIssuer for Let's Encrypt
# resource "kubectl_manifest" "letsencrypt_cluster_issuer" {
#   depends_on = [azurerm_kubernetes_cluster.capstone, helm_release.cert_manager]
#   yaml_body  = <<YAML
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-cluster-issuer
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: greatvictor.anjorin@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-cluster-issuer-key
#     solvers:
#     - http01:
#         ingress:
#           class: nginx
# YAML
# }

# Time API Ingress
resource "kubernetes_ingress_v1" "time_api" {
  metadata {
    name = "time-api-ingress"
    annotations = {
      "cert-manager.io/cluster-issuer" = module.cert_manager.cluster_issuer_name
      # "cert-manager.io/cluster-issuer"           = "letsencrypt"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["api.mywonder.works"]
      secret_name = "letsencrypt-cert"
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
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [module.cert_manager, kubernetes_service.time_api, azurerm_kubernetes_cluster.capstone]
}

# Load Test Job
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
          args    = ["for i in $(seq 1 1000); do wget -q -O- http://time-api-service/time; sleep 0.1; done"]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }

  depends_on = [kubernetes_service.time_api, kubernetes_ingress_v1.time_api, azurerm_kubernetes_cluster.capstone]
}