resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.240.0.0/16"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.0.0/22"]
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "aks_public_ip" {
  name                = "${var.cluster_name}-public-ip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "aks_nat_gateway" {
  name                    = "${var.cluster_name}-natgw"
  location                = azurerm_resource_group.aks_rg.location
  resource_group_name     = azurerm_resource_group.aks_rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = {
    Environment = "test"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "aks_natgw_association" {
  nat_gateway_id       = azurerm_nat_gateway.aks_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.aks_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "aks_natgw_association" {
  nat_gateway_id = azurerm_nat_gateway.aks_nat_gateway.id
  subnet_id      = azurerm_subnet.aks_subnet.id
}

output "gateway_ips" {
  value = azurerm_public_ip.aks_public_ip
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.cluster_name}-nsg"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location

  security_rule {
    name                       = "allow-https-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http-access"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
