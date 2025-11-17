# This file contains the Kubernetes Network Policies for the time-api namespace.
# Updated to support the world clock application architecture with separate backend and frontend

# Default deny all traffic for backend pods
resource "kubernetes_network_policy_v1" "backend_default_deny" {
  metadata {
    name      = "backend-default-deny-all"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-backend"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# Default deny all traffic for frontend pods
resource "kubernetes_network_policy_v1" "frontend_default_deny" {
  metadata {
    name      = "frontend-default-deny-all"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-frontend"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# Allow DNS for backend pods
resource "kubernetes_network_policy_v1" "backend_allow_dns" {
  metadata {
    name      = "backend-allow-dns-access"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-backend"
      }
    }

    policy_types = ["Egress"]

    egress {
      ports {
        protocol = "UDP"
        port     = 53
      }
      ports {
        protocol = "TCP"
        port     = 53
      }
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.backend_default_deny]
}

# Allow DNS for frontend pods
resource "kubernetes_network_policy_v1" "frontend_allow_dns" {
  metadata {
    name      = "frontend-allow-dns-access"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-frontend"
      }
    }

    policy_types = ["Egress"]

    egress {
      ports {
        protocol = "UDP"
        port     = 53
      }
      ports {
        protocol = "TCP"
        port     = 53
      }
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.frontend_default_deny]
}

# Allow ingress traffic to backend from nginx ingress controller and load tests
resource "kubernetes_network_policy_v1" "allow_ingress_to_backend" {
  metadata {
    name      = "allow-ingress-to-backend"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-backend"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      # Allow traffic from nginx ingress controller
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "ingress-nginx"
          }
        }
      }
      # Allow traffic from backend load test job
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "time-api"
          }
        }
        pod_selector {
          match_labels = {
            "job-name" = "backend-loadtest"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 5000
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.backend_default_deny]
}

# Allow ingress traffic to frontend from nginx ingress controller and load tests
resource "kubernetes_network_policy_v1" "allow_ingress_to_frontend" {
  metadata {
    name      = "allow-ingress-to-frontend"
    namespace = "time-api"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "world-clock-frontend"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      # Allow traffic from nginx ingress controller
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "ingress-nginx"
          }
        }
      }
      # Allow traffic from frontend load test job
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "time-api"
          }
        }
        pod_selector {
          match_labels = {
            "job-name" = "frontend-loadtest"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 80
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.frontend_default_deny]
}
