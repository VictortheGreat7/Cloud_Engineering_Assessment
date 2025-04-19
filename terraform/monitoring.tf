resource "azurerm_log_analytics_workspace" "timeapi_law" {
  name                = "${azurerm_resource_group.time_api_rg.name}-law"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name
  sku                 = "PerGB2018"
  # retention_in_days   = 30
}

resource "azurerm_resource_provider_registration" "monitor" {
  name = "Microsoft.Monitor"
}

resource "azurerm_monitor_workspace" "timeapi_prometheus" {
  name                = "timeapi-prometheus-workspace"
  location            = azurerm_resource_group.time_api_rg.location
  resource_group_name = azurerm_resource_group.time_api_rg.name

  depends_on = [azurerm_resource_provider_registration.monitor]
}

# Connect AKS to Azure Monitor managed Prometheus
resource "azurerm_monitor_data_collection_endpoint" "timeapi_prometheus_dce" {
  name                = "timeapi-prom-dce"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  location            = azurerm_resource_group.time_api_rg.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "timeapi_prometheus_dcr" {
  name                        = "timeapi-prom-dcr"
  resource_group_name         = azurerm_resource_group.time_api_rg.name
  location                    = azurerm_resource_group.time_api_rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.timeapi_prometheus_dce.id

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.timeapi_prometheus.id
      name               = "prometheus-metrics"
    }
  }

  data_sources {
    prometheus_forwarder {
      name    = "aks-prometheus-metrics"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  data_flow {
    destinations = ["prometheus-metrics"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }
}

# Associate the data collection rule with the AKS cluster
resource "azurerm_monitor_data_collection_rule_association" "timeapi_prometheus_dcra" {
  name                    = "timeapi-prom-dcra"
  target_resource_id      = azurerm_kubernetes_cluster.time_api_cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.timeapi_prometheus_dcr.id
}

resource "azurerm_dashboard_grafana" "timeapi_grafana" {
  name                              = "timeapi-grafana-dashboard"
  location                          = azurerm_resource_group.time_api_rg.location
  resource_group_name               = azurerm_resource_group.time_api_rg.name
  grafana_major_version             = 10
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true # Set to false for private access only

  identity {
    type = "SystemAssigned"
  }
  sku = "Standard"

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.timeapi_prometheus.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "timeapi_audit_logs" {
  name                       = "timeapi-audit-logs"
  target_resource_id         = azurerm_kubernetes_cluster.time_api_cluster.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.timeapi_law.id

  enabled_log {
    category = "kube-audit"
    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "kube-audit-admin"
    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "kube-apiserver"
    retention_policy {
      enabled = false
      # days    = 30
    }
  }

  enabled_log {
    category = "kube-controller-manager"
    retention_policy {
      enabled = false
      # days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
      # days    = 30
    }
  }
}

resource "azurerm_dashboard_grafana_managed_private_endpoint" "timeapi_grafana_prometheus_endpoint" {
  name                         = "timeapi-grafana-prometheus-endpoint"
  location                     = azurerm_resource_group.time_api_rg.location
  grafana_id                   = azurerm_dashboard_grafana.timeapi_grafana.id
  private_link_resource_id     = azurerm_monitor_workspace.timeapi_prometheus.id
  private_link_resource_region = azurerm_monitor_workspace.timeapi_prometheus.location
}

