# Data sources to reference main infrastructure
# These allow the runner infrastructure to be deployed separately
# while still accessing shared resources like VNet and Resource Group

/*
data "azurerm_resource_group" "time_api_rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "time_api_vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.time_api_rg.name
}
*/
