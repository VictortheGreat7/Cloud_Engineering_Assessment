# Default Deny Policy for the application namespace
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = "default" # Or your specific application namespace if different
  }

  spec {
    pod_selector {} # Selects all pods in the namespace

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster] # Ensure cluster is ready
}

# Allow Ingress to time-api from NGINX Ingress Controller
resource "kubernetes_network_policy_v1" "allow_nginx_ingress" {
  metadata {
    name      = "allow-time-api-ingress-from-nginx"
    namespace = "default" # Or your specific application namespace
  }

  spec {
    pod_selector {
      # To identify the correct labels for the API server in your cluster, you can use the following command:
      # kubectl get pods -n kube-system -l k8s-app=kube-apiserver -o jsonpath="{.items[*].metadata.labels}"
      match_labels = {
        app = "time-api"
      }
    }

    # Only ingress traffic is allowed for this policy to ensure that the time-api pods can receive traffic from the NGINX Ingress Controller.
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system" # Assuming NGINX Ingress Controller is in 'ingress-nginx' namespace.  Adjust if different.
          }
        }
        pod_selector {
          # match_labels = {
          #   "app.kubernetes.io/name" = "ingress-nginx" # Standard label for NGINX Ingress pods
          # }
        }
      }

      ports {
        protocol = "TCP"
        port     = 5000
      }
    }
  }

  depends_on = [module.nginx-controller] # Ensure NGINX is deployed
}

# Allow Egress for DNS resolution from time-api pods
resource "kubernetes_network_policy_v1" "allow_dns_egress" {
  metadata {
    name      = "time-api-allow-dns-egress"
    namespace = "default" # Or your specific application namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    # Only egress traffic is allowed for this policy to ensure that the time-api pods can perform outbound communication, such as DNS resolution or API calls.
    policy_types = ["Ingress","Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "job-name" = "time-api-loadtest" # Selects the loadtest job pods
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 5000
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
}

# NGINX Ingress Controller Network Policy
resource "kubernetes_network_policy_v1" "allow_nginx_controller" {
  metadata {
    name      = "nginx-ingress-controller-policy"
    namespace = "kube-system" # Adjust this to the actual namespace where NGINX is deployed
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "ingress-nginx"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {} # Allow all ingress traffic from outside the cluster (this is the purpose of an Ingress)

    # Allow egress to your time-api pods
    egress {
      to {
        pod_selector {
          match_labels = {
            app = "time-api"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 5000 # The target port of your time-api service
      }
    }

    # Allow egress for DNS lookups (crucial for hostname resolution)
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

  depends_on = [module.nginx-controller]
}

# Cert-Manager Controller Network Policy
resource "kubernetes_network_policy_v1" "allow_certmanager_controller" {
  metadata {
    name      = "cert-manager-controller-policy"
    namespace = "cert-manager"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/component" = "controller" # Selects cert-manager controller pods
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {} # Allow internal communication within cert-manager namespace
      }
    }

    # Allow egress to Kubernetes API server
    egress {
      to {
        # General approach for API server access:
        # Allow egress to the 'kubernetes' service within the cluster.
        # For a more specific approach, find your AKS API server's CIDR.

        # Use namespaceSelector and podSelector for kube-system/kube-apiserver if labels are stable.
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system" # Target the kube-system namespace where the Kubernetes API server resides
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-apiserver" # Restrict egress to Kubernetes API server pods
          }
        }
      }
      # Selects all pods (too broad, ideally specify API server labels).
      # pod_selector {} # Allow egress to the Kubernetes API server
      ports {
        protocol = "TCP"
        port     = 443 # Default HTTPS port for API server
      }
    }

    # Allow egress to external ACME servers (Let's Encrypt)
    egress {
      ports {
        protocol = "TCP"
        port     = 443
      }
      ports {
        protocol = "TCP"
        port     = 80 # For HTTP-01 challenges
      }
    }

    # Allow egress for DNS resolution
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

    # Allow egress to Name.com API (for DNS01 challenge)
    egress {
      to {
        ip_block {
          # YOU MUST REPLACE THIS WITH THE ACTUAL IP RANGES FOR NAME.COM API IF POSSIBLE
          # A value of "0.0.0.0/0" is highly permissive and should be narrowed down.
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        protocol = "TCP"
        port     = 443
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# Cert-Manager Webhook Network Policy
resource "kubernetes_network_policy_v1" "allow_certmanager_webhook" {
  metadata {
    name      = "cert-manager-webhook-policy"
    namespace = "cert-manager"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/component" = "webhook" # Selects cert-manager webhook pods
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from Kubernetes API server
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-apiserver"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 10250 # Or the port the webhook listens on (check cert-manager docs)
      }
    }

    # Allow egress to Kubernetes API server
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system" # Target the kube-system namespace where the Kubernetes API server resides
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-apiserver" # Restrict egress to Kubernetes API server pods
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 443 # Or the API server's port
      }
    }

    # Allow egress for DNS resolution
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

  depends_on = [helm_release.cert_manager]
}

# Name.com Webhook Network Policy
resource "kubernetes_network_policy_v1" "allow_namecom_webhook" {
  metadata {
    name      = "namecom-webhook-policy"
    namespace = "cert-manager"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "cert-manager-webhook-namecom" # Based on your helm release chart name
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from cert-manager controller
    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/component" = "controller" # Selects cert-manager controller pods
          }
        }
      }
    }

    # Allow egress to Name.com API
    egress {
      to {
        ip_block {
          # YOU MUST REPLACE THIS WITH THE ACTUAL IP RANGES FOR NAME.COM API IF POSSIBLE
          cidr = "0.0.0.0/0" # Highly permissive, narrow this down
        }
      }
      ports {
        protocol = "TCP"
        port     = 443
      }
    }

    # Allow egress for DNS resolution
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

  depends_on = [helm_release.namecom_webhook]
}

# Network Policy for Time API Load Test Job
resource "kubernetes_network_policy_v1" "allow_loadtest" {
  metadata {
    name      = "allow-loadtest-to-time-api"
    namespace = "default" # Or your specific application namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "job-name" = "time-api-loadtest" # Selects the loadtest job pods
      }
    }

    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "time-api" # Allow egress to time-api pods
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 5000 # The target port of your time-api service
      }
    }

    # Allow egress for DNS resolution (for `time-api-service.default.svc.cluster.local`)
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
}
