# This file contains the terraform code to create the AKS cluster.

resource "random_pet" "time_api" {
}

resource "azurerm_resource_group" "time_api_rg" {
  name     = "rg-${random_pet.time_api.id}-time-api"
  location = var.region
}

resource "azurerm_kubernetes_cluster" "time_api_cluster" {
  name                = "aks-${azurerm_resource_group.time_api_rg.name}-cluster"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  location            = azurerm_resource_group.time_api_rg.location
  dns_prefix          = "dns-${azurerm_resource_group.time_api_rg.name}-cluster"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.default_version
  node_resource_group = "nrg-aks-${azurerm_resource_group.time_api_rg.name}-cluster"

  # api_server_access_profile {
  #   authorized_ip_ranges = ["${var.workstation_IP_address}", "${azurerm_public_ip.time_api_public_ip.ip_address}/32"]
  # }

  default_node_pool {
    name                 = "default"
    vm_size              = "Standard_D2_v2"
    auto_scaling_enabled = true
    max_count            = 2
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.time_api_subnet.id
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
    admin_group_object_ids = [azuread_group.time_api_admins.object_id]
  }


  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip    = "172.16.0.10"
    service_cidr      = "172.16.0.0/16"
    outbound_type     = "userAssignedNATGateway"
    nat_gateway_profile {
      idle_timeout_in_minutes = 4
    }
  }

  depends_on = [azuread_group.time_api_admins, azurerm_subnet_nat_gateway_association.time_api_natgw_subnet_association, azurerm_nat_gateway_public_ip_association.time_api_natgw_public_ip_association]

  tags = {
    Environment = "test"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config
  sensitive = true
}