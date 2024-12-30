# This file contains the terraform code to create the AKS cluster.

resource "azurerm_resource_group" "aks_rg" {
  name     = var.rg_name
  location = var.region
}

resource "azurerm_kubernetes_cluster" "capstone" {
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  dns_prefix          = "${var.rg_name}-cluster"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.default_version
  node_resource_group = "${var.cluster_name}-nrg"

  api_server_access_profile {
    authorized_ip_ranges = ["${var.workstation_IP_address}", "${azurerm_public_ip.aks_public_ip.ip_address}", "105.113.109.154/32"]
  }

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
    admin_group_object_ids = [azuread_group.aks_admins.object_id]
  }


  network_profile {
    network_plugin = "azure"
    # network_policy    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip    = "172.16.0.10"
    service_cidr      = "172.16.0.0/16"
    outbound_type     = "userAssignedNATGateway"
    nat_gateway_profile {
      idle_timeout_in_minutes = 4
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_workspace.id
  }

  # lifecycle {
  #   ignore_changes = [
  #     network_profile[0].nat_gateway_profile
  #   ]
  # }

  depends_on = [azuread_group.aks_admins, azurerm_subnet_nat_gateway_association.aks_natgw_association, azurerm_nat_gateway_public_ip_association.aks_natgw_association, azurerm_log_analytics_workspace.aks_workspace, azurerm_resource_group.aks_rg]

  tags = {
    Environment = "test"
  }
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.capstone.kube_admin_config
  sensitive = true
}