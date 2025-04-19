resource "azurerm_monitor_action_group" "timeapi_security_team" {
  name                = "timeapi-security-team-alerts"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  short_name          = "secteam"

  email_receiver {
    name          = "Great-Victor Anjorin"
    email_address = "greatvictor.anjorin@gmail.com"
  }
}

resource "azurerm_monitor_metric_alert" "time_api_high_cpu" {
  name                = "timeapi-high-cpu"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  scopes              = [azurerm_kubernetes_cluster.time_api_cluster.id]
  description         = "Alert for high CPU"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name            = "Percentage CPU"
    metric_namespace       = "Microsoft.ContainerService/managedClusters"
    aggregation            = "Average"
    operator               = "GreaterThan"
    threshold              = 80
    skip_metric_validation = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "unusual_traffic" {
  name                = "unusual-traffic-alert"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  location            = azurerm_resource_group.time_api_rg.location

  action {
    action_group  = [azurerm_monitor_action_group.timeapi_security_team.id]
    email_subject = "Unusual Traffic Pattern Detected"
  }

  data_source_id = azurerm_log_analytics_workspace.timeapi_law.id
  description    = "Alert for unusual traffic pattern"
  severity       = 2
  frequency      = 5
  time_window    = 15
  query          = <<-QUERY
      AzureDiagnostics
      | where Category == "NetworkSecurityGroupFlowEvent"
      | where action_s == "Deny"
      | summarize count() by bin(TimeGenerated, 5m), src_ip_s
      | where count_ > 100
  QUERY
  enabled        = true

  trigger {
    operator  = "GreaterThan"
    threshold = 100
  }
}

# Create a Prometheus rule group for port 80 traffic monitoring
resource "azurerm_monitor_alert_prometheus_rule_group" "port_80_alerts" {
  name                = "port-80-traffic-alerts"
  resource_group_name = azurerm_resource_group.time_api_rg.name
  location            = azurerm_resource_group.time_api_rg.location
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.timeapi_prometheus.id]

  rule {
    enabled    = true
    alert      = "HttpPortTrafficBlocked"
    expression = "sum(rate(istio_requests_total{destination_port=\"80\", response_code=~\"4.*|5.*\"}[5m])) by (source_workload, destination_service) > 5"

    for      = "PT5M"
    severity = 2

    action {
      action_group_id = azurerm_monitor_action_group.timeapi_security_team.id
    }
  }

  rule {
    enabled    = true
    alert      = "HttpTrafficRedirected"
    expression = "sum(rate(istio_requests_total{source_port=\"80\", response_code=\"301\"}[5m])) by (source_workload, destination_service) > 10"

    for      = "PT5M"
    severity = 3

    action {
      action_group_id = azurerm_monitor_action_group.timeapi_security_team.id
    }
  }
}