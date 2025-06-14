# Default Deny Policy for the application namespace
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = "default"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

resource "kubernetes_network_policy_v1" "allow_dns" {
  metadata {
    name      = "allow-dns-access"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      ports {
        protocol = "UDP"
        port     = 53
      }
      ports {
        protocol = "TCP"
        port     = 53
      }
    }

    egress {
      ports {
        protocol = "UDP"
        port     = 53
      }
      ports {
        protocol = "TCP"
        port     = 53
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.default_deny]
}

resource "kubernetes_network_policy_v1" "allow_nginx_ingress" {
  metadata {
    name      = "allow-time-api-ingress-from-nginx"
    namespace = "default" # Applies to pods in the default namespace
  }

  spec {
    # Selects the time-api pods to which this policy applies
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    policy_types = ["Ingress"]

    # Defines the allowed incoming traffic
    ingress {
      # Allow traffic from specific pods
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name"      = "ingress-nginx"
            "app.kubernetes.io/component" = "controller"
          }
        }
      }
      # Allow traffic on specific ports
      ports {
        protocol = "TCP"
        port     = 5000 # The container_port of your time-api deployment
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.default_deny]
}

resource "kubernetes_network_policy_v1" "allow_loadtest" {
  metadata {
    name      = "allow-ingress-from-loadtest"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        # Select pods created by the time-api-loadtest job.
        # Job pods typically get a 'job-name' label derived from the job's metadata.name.
        pod_selector {
          match_labels = {
            "job-name" = "time-api-loadtest"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 5000
      }
    }
  }

  depends_on = [kubernetes_network_policy_v1.default_deny]
}
