# This script provisions the Kubernetes resources needed for the time API application.

# This resource creates a Kubernetes namespace for the time API microservice.
resource "kubernetes_namespace_v1" "time_api" {
  metadata {
    name = "time-api"
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# This resource creates a ConfigMap in the Kubernetes cluster.
# A ConfigMap is used to store non-confidential data in key-value pairs.
# ConfigMaps are used to decouple environment-specific configuration from the container images, allowing for more flexible deployments.
# The time zone is set to UTC, but this can be changed as needed.
resource "kubernetes_config_map_v1" "time_api_config" {
  metadata {
    name      = "time-api-config"
    namespace = "time-api"
  }

  data = {
    TIME_ZONE = "UTC"
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

# This module deploys the NGINX Ingress Controller to the Kubernetes cluster.
# It provides a way to expose HTTP and HTTPS routes from outside the cluster to the appropriate service based on the defined rules.
module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = ">=2.3.0"

  create_namespace = true
  namespace        = "nginx-ingress"

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}
