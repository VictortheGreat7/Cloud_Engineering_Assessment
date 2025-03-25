module "nginx-controller" {
  source = "terraform-iaac/nginx-controller/helm"

  depends_on = [azurerm_kubernetes_cluster.capstone]
}

module "certmanager" {
  source     = "dodevops/certmanager/azure"
  version    = "0.2.0"
  depends_on = [module.nginx-controller]

}

# Time API ConfigMap
resource "kubernetes_config_map" "time_api_config" {
  metadata {
    name = "time-api-config"
  }

  data = {
    TIME_ZONE = "UTC"
  }

  depends_on = [azurerm_kubernetes_cluster.capstone]
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

  depends_on = [kubernetes_deployment.time_api]
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "certmanager"
    }
    spec = {
      acme = {
        email                 = "greatvictor.anjorin@gmail.com"
        server                = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "certmanager"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [module.certmanager]
}

# Time API Ingress
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

  depends_on = [kubernetes_service.time_api, module.certmanager, resource.kubectl_manifest.cluster_issuer]
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
    backoff_limit = 4
    # Add active deadline seconds to ensure the job completes
    active_deadline_seconds = 300
  }

  depends_on = [kubernetes_service.time_api, kubernetes_ingress_v1.time_api]

  timeouts {
    create = "5m"
  }
}
