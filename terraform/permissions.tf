# This file contains the terraform code to create the necessary permissions for the AKS cluster

resource "azuread_group" "aks_admins" {
  display_name     = "aks-admins"
  owners           = [var.my_user_object_id]
  security_enabled = true

  members = [var.my_user_object_id, data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "cluster_role_assignment" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.capstone.identity[0].principal_id

  depends_on = [
    azurerm_kubernetes_cluster.capstone
  ]
}

# Assign Contributor role to the AAD group for the Resource Group
resource "azurerm_role_assignment" "aks_admins_rg_access" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.aks_admins.object_id

  depends_on = [
    azurerm_resource_group.aks_rg
  ]
}
