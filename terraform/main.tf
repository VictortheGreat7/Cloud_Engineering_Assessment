# This file contains the terraform code to create the AKS cluster.

resource "azurerm_resource_group" "aks_rg" {
  name     = var.rg_name
  location = var.region
}

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

resource "azurerm_kubernetes_cluster" "capstone" {
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  dns_prefix          = "${var.rg_name}-cluster"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.default_version
  node_resource_group = "${var.cluster_name}-nrg"

  # api_server_access_profile {
  #   authorized_ip_ranges = var.allowed_source_addresses
  # }

  default_node_pool {
    name                 = "default"
    vm_size              = "Standard_D2_v2"
    auto_scaling_enabled = true
    max_count            = 2
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "test"
      "nodepoolos"    = "linux"
    }
    tags = {
      "nodepool-type" = "system"
      "environment"   = "test"
      "nodepoolos"    = "linux"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = [azuread_group.aks_admins.id]
  }


  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip    = "172.16.0.10"
    service_cidr      = "172.16.0.0/16"
    outbound_type     = "userAssignedNATGateway"
    # nat_gateway_profile {
    #   idle_timeout_in_minutes = 4
    # }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  lifecycle {
    ignore_changes = [
      network_profile[0].nat_gateway_profile
    ]
  }

  depends_on = [azurerm_subnet_nat_gateway_association.aks_natgw_association, azurerm_nat_gateway_public_ip_association.aks_natgw_association, azuread_group.aks_admins, azurerm_log_analytics_workspace.aks]

  tags = {
    Environment = "test"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.capstone.kube_admin_config
  sensitive = true
}