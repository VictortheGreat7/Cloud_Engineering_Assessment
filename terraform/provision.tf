# This file contains the Terraform configuration for deploying the Time API application on Azure Kubernetes Service (AKS).

resource "kubernetes_namespace_v1" "time_api" {
  metadata {
    name = "time-api"
  }

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}

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

module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = ">=2.3.0"

  depends_on = [azurerm_kubernetes_cluster.time_api_cluster]
}
