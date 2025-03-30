# This file is responsible for deploying the time API application to the Azure Kubernetes Service (AKS) cluster.

# This module deploys the NGINX Ingress Controller to the Kubernetes cluster.
# It provides a way to expose HTTP and HTTPS routes from outside the cluster to the appropriate service based on the defined rules.
module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = ">=2.3.0"

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# Add a data source to get the ingress IP after it's created
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "kube-system" # Adjust if your controller is in a different namespace
  }
  depends_on = [module.nginx-controller]
}

# Output the ingress IP for reference
output "ingress_ip" {
  value = data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
}

# Create the DNS Zone
resource "azurerm_dns_zone" "mywonder_works" {
  name                = "mywonder.works"
  resource_group_name = azurerm_resource_group.time_api_rg.name

  tags = {
    environment = "test"
  }

  depends_on = [module.nginx-controller]
}

resource "azurerm_dns_a_record" "api" {
  name                = "api"
  zone_name           = azurerm_dns_zone.mywonder_works.name
  resource_group_name = azurerm_dns_zone.mywonder_works.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip]

  depends_on = [module.nginx-controller, data.kubernetes_service.nginx_ingress]
}

# Output the name servers - you'll need these to update your domain registrar
output "name_servers" {
  value = azurerm_dns_zone.mywonder_works.name_servers
}

module "certmanager" {
  source  = "dodevops/certmanager/azure"
  version = "0.2.0"

  set-list = [
    {
      name  = "crds.create"
      value = "true"
      type  = "auto"
    }
  ]
  cluster-issuers-yaml = format(<<-YAML
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
                  resourceGroupName: "%s"
                  subscriptionID: "%s"
                  hostedZoneName: "%s"
                  environment: AzurePublicCloud
                  managedIdentity:
                    clientID: "%s"
YAML
    , azurerm_dns_zone.mywonder_works.resource_group_name,
    "d31507f4-324c-4bd1-abe1-5cdf45cba77d",
    azurerm_dns_zone.mywonder_works.name,
  var.my_user_object_id)

  depends_on = [module.nginx-controller]
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

  depends_on = [kubernetes_service.time_api, module.certmanager]
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
