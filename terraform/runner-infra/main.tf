# Self-Hosted GitHub Actions Runner Infrastructure
# This Terraform configuration creates ONLY the runner VM and its dependencies
# It is separate from the AKS cluster and application deployment

# Include base infrastructure (VNet, Resource Group, etc.) that runner needs
# These are shared with the main cluster but runner-specific resources are isolated here

# Note: This file should reference the main infrastructure via data sources
# when the runner infrastructure is enabled

# Self-hosted runner resources
# Uncomment to enable self-hosted runner infrastructure

/*
resource "azurerm_subnet" "runner_subnet" {
  name                 = "snet-runner"
  resource_group_name  = data.azurerm_resource_group.time_api_rg.name
  virtual_network_name = data.azurerm_virtual_network.time_api_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "runner_nsg" {
  name                = "nsg-runner"
  location            = data.azurerm_resource_group.time_api_rg.location
  resource_group_name = data.azurerm_resource_group.time_api_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "runner_nsg_association" {
  subnet_id                 = azurerm_subnet.runner_subnet.id
  network_security_group_id = azurerm_network_security_group.runner_nsg.id
}

resource "azurerm_public_ip" "runner_pip" {
  name                = "pip-runner"
  location            = data.azurerm_resource_group.time_api_rg.location
  resource_group_name = data.azurerm_resource_group.time_api_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "runner_nic" {
  name                = "nic-runner"
  location            = data.azurerm_resource_group.time_api_rg.location
  resource_group_name = data.azurerm_resource_group.time_api_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.runner_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.runner_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "runner_vm" {
  name                = "vm-runner-${data.azurerm_resource_group.time_api_rg.name}"
  location            = data.azurerm_resource_group.time_api_rg.location
  resource_group_name = data.azurerm_resource_group.time_api_rg.name
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.runner_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("${path.module}/ssh_keys/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
    runner_token = var.runner_token
  }))

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "test"
    Role        = "github-runner"
  }
}

output "runner_ssh_command" {
  value       = "ssh -i ssh_keys/id_rsa adminuser@${azurerm_public_ip.runner_pip.ip_address}"
  description = "SSH command to connect to the self-hosted runner"
  sensitive   = false
}

output "runner_public_ip" {
  value       = azurerm_public_ip.runner_pip.ip_address
  description = "Public IP address of the self-hosted runner"
}
*/

# Placeholder - uncomment resources above to enable runner infrastructure
# See SELF_HOSTED_RUNNER_GUIDE.md for setup instructions
