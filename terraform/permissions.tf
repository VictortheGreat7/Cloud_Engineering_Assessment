# This file contains the terraform code to create the necessary permissions for the time_api cluster

# This creates a new Azure AD group for access to the Time API
resource "azuread_group" "time_api_admins" {
  display_name     = "time_api-admins"
  owners           = [var.my_user_object_id]
  security_enabled = true

  members = [var.my_user_object_id, data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "cluster_role_assignment" {
  scope                = azurerm_resource_group.time_api_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.time_api_cluster.identity[0].principal_id

  depends_on = [
    azurerm_kubernetes_cluster.time_api_cluster
  ]
}

# # Assign Contributor role to the AAD group for the Resource Group
# resource "azurerm_role_assignment" "time_api_admins_rg_access" {
#   scope                = azurerm_resource_group.time_api_rg.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_group.time_api_admins.object_id

#   depends_on = [
#     azurerm_resource_group.time_api_rg
#   ]
# }
