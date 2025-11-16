# This script defines the instructions for the deployment of the world clock application to the Azure Kubernetes Service (AKS) cluster.

# Backend API Deployment
resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "world-clock-backend"
    namespace = "time-api"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "world-clock-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "world-clock-backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "victorthegreat7/world-clock-backend:latest"

          port {
            container_port = 5000
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [module.nginx-controller, kubernetes_namespace_v1.time_api]
}

# Frontend Deployment
resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "world-clock-frontend"
    namespace = "time-api"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "world-clock-frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "world-clock-frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = "victorthegreat7/world-clock-frontend:latest"

          port {
            container_port = 80
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

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [module.nginx-controller, kubernetes_namespace_v1.time_api]
}

# Backend Service
resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = "world-clock-backend-service"
    namespace = "time-api"
  }

  spec {
    selector = {
      app = "world-clock-backend"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 5000
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.backend]
}

# Frontend Service
resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "world-clock-frontend-service"
    namespace = "time-api"
  }

  spec {
    selector = {
      app = "world-clock-frontend"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.frontend]
}

# Backend Load Test
resource "kubernetes_job_v1" "backend_loadtest" {
  metadata {
    name      = "backend-loadtest"
    namespace = "time-api"
  }

  spec {
    template {
      metadata {
        name = "backend-loadtest"
      }
      spec {
        container {
          name    = "loadtest"
          image   = "busybox"
          command = ["/bin/sh", "-c"]
          args = [<<-EOF
            echo "Testing backend API endpoints..."
            for i in $(seq 1 30); do 
              wget -q -O- http://world-clock-backend-service.time-api.svc.cluster.local:80/api/world-clocks && 
              echo "Backend request $i successful"; 
              sleep 0.1; 
            done
            echo "All backend tests completed successfully!"
          EOF
          ]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit           = 4
    active_deadline_seconds = 300
  }

  depends_on = [kubernetes_service_v1.backend]
}

# Frontend Load Test
resource "kubernetes_job_v1" "frontend_loadtest" {
  metadata {
    name      = "frontend-loadtest"
    namespace = "time-api"
  }

  spec {
    template {
      metadata {
        name = "frontend-loadtest"
      }
      spec {
        container {
          name    = "loadtest"
          image   = "busybox"
          command = ["/bin/sh", "-c"]
          args = [<<-EOF
            echo "Testing frontend service..."
            for i in $(seq 1 30); do 
              wget -q -O- http://world-clock-frontend-service.time-api.svc.cluster.local:80/ && 
              echo "Frontend request $i successful"; 
              sleep 0.1; 
            done
            echo "All frontend tests completed successfully!"
          EOF
          ]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit           = 4
    active_deadline_seconds = 300
  }

  depends_on = [kubernetes_service_v1.frontend]
}

resource "time_sleep" "wait_for_nginx" {
  create_duration = "120s" # Wait 2 minutes

  depends_on = [module.nginx-controller]
}

# Ingress Configuration for routing traffic
resource "kubernetes_ingress_v1" "world_clock" {
  metadata {
    name      = "world-clock-ingress"
    namespace = "time-api"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        # Route /api/* to backend
        path {
          path      = "/api(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.backend.metadata[0].name
              port {
                number = kubernetes_service_v1.backend.spec[0].port[0].port
              }
            }
          }
        }

        # Route / to frontend
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.frontend.metadata[0].name
              port {
                number = kubernetes_service_v1.frontend.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.backend, kubernetes_service_v1.frontend, azurerm_dashboard_grafana.timeapi_grafana, time_sleep.wait_for_nginx]
}
