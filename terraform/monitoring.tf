resource "azurerm_log_analytics_workspace" "timeapi_law" {
  name                = "${azurerm_resource_group.time_api_rg.name}-law"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name
}

resource "azurerm_monitor_workspace" "monitor_workspace" {
  name                = "${azurerm_resource_group.time_api_rg.name}-monitor-workspace"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name
}

resource "azurerm_monitor_diagnostic_setting" "timeapi_audit_logs" {
  name                       = "${azurerm_resource_group.time_api_rg.name}-audit-logs"
  target_resource_id         = azurerm_kubernetes_cluster.time_api_cluster.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.timeapi_law.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_dashboard_grafana" "timeapi_grafana" {
  name                = "timeapi-grafana"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name

  grafana_major_version             = 11
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true # Set to false for private access only

  identity {
    type = "SystemAssigned"
  }
  sku = "Standard"

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.monitor_workspace.id
  }
}
