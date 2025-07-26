# This file contains the main Terraform configuration for creating an Azure Kubernetes Service (AKS) cluster for the Time API application.

resource "random_pet" "time_api" {
}

resource "azurerm_resource_group" "time_api_rg" {
  name     = "rg-${random_pet.time_api.id}-time-api"
  location = var.region
}

resource "azurerm_linux_virtual_machine" "gha_vm" {
  name                = "gha-${azurerm_resource_group.time_api_rg.name}-vm"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  location            = azurerm_resource_group.time_api_rg.location
  size                = "Standard_D2_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.gha_nic.id,
  ]

   admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/ssh_keys/id_rsa.pub")
  }

  admin_password = "Terraform123!" # Only for demo; use SSH in production

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "gha-os-disk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-noble"
    sku       = "24_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
}
