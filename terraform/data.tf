# This file contains the data sources that are used in the Terraform configuration.
data "azurerm_kubernetes_service_versions" "current" {
  location        = var.region
  include_preview = false
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

# data "azurerm_kubernetes_cluster" "credentials" {
#   name                = azurerm_kubernetes_cluster.capstone.name
#   resource_group_name = azurerm_resource_group.aks_rg.name
# }