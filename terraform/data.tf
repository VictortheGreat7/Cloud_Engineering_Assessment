# This file contains the data sources that are used in the Terraform configuration.
data "azurerm_kubernetes_service_versions" "current" {
  location        = var.region
  include_preview = false
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_cluster" "time_api_cluster" {
  name                = azurerm_kubernetes_cluster.time_api_cluster.name
  resource_group_name = azurerm_kubernetes_cluster.time_api_cluster.resource_group_name

  depends_on = [
    azurerm_kubernetes_cluster.time_api_cluster
  ]
}

# Add a data source to get the ingress IP after it's created
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "kube-system" # Adjust if your controller is in a different namespace
  }
  depends_on = [module.nginx-controller]
}

# data "azurerm_kubernetes_cluster" "credentials" {
#   name                = azurerm_kubernetes_cluster.capstone.name
#   resource_group_name = azurerm_resource_group.aks_rg.name
# }