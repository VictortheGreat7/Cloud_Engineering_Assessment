# Self-Hosted GitHub Actions Runner Infrastructure
# This file contains resources for deploying a self-hosted runner for private cluster access
# Uncomment these resources when deploying to a private AKS cluster

/*
# Subnet for self-hosted runner VM
resource "azurerm_subnet" "runner_subnet" {
  name                 = "snet-runner"
  resource_group_name  = azurerm_resource_group.time_api_rg.name
  virtual_network_name = azurerm_virtual_network.time_api_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for runner subnet
resource "azurerm_network_security_group" "runner_nsg" {
  name                = "nsg-runner"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name

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

# Public IP for runner VM
resource "azurerm_public_ip" "runner_pip" {
  name                = "pip-runner"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface for runner VM
resource "azurerm_network_interface" "runner_nic" {
  name                = "nic-runner"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.runner_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.runner_pip.id
  }
}

# Virtual Machine for self-hosted runner
resource "azurerm_linux_virtual_machine" "runner_vm" {
  name                = "vm-runner-${random_pet.time_api.id}"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name
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

# Output SSH command for connecting to runner
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

# Note: To enable self-hosted runner infrastructure:
# 1. Create ssh_keys directory: mkdir -p terraform/ssh_keys
# 2. Generate SSH key pair: ssh-keygen -t rsa -b 4096 -C "github-runner" -f terraform/ssh_keys/id_rsa
# 3. Create cloud-init.yaml.tpl file (see cloud-init-template.yaml for reference)
# 4. Add RUNNER_TOKEN to GitHub secrets
# 5. Uncomment the resources above
# 6. Uncomment private_cluster_enabled in main.tf
# 7. Update GitHub Actions workflow to use self-hosted runner
