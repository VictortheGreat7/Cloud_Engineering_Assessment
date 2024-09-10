# resource "azurerm_monitor_metric_alert" "aks_cpu_alert" {
#   name                = "aks-cpu-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_kubernetes_cluster.capstone.id]

#   criteria {
#     metric_namespace = "Insights.Container/nodes"
#     metric_name      = "cpuUsagePercentage"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.aks_alerts.id
#   }
# }

# resource "azurerm_monitor_metric_alert" "aks_memory_alert" {
#   name                = "aks-memory-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_kubernetes_cluster.capstone.id]

#   criteria {
#     metric_namespace = "Insights.Container/nodes"
#     metric_name      = "memoryWorkingSetPercentage"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.aks_alerts.id
#   }
# }

# resource "azurerm_monitor_scheduled_query_rules_alert" "aks_pod_restart" {
#   name                = "aks-pod-restart-alert"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name

#   action {
#     action_group  = [azurerm_monitor_action_group.aks_alerts.id]
#     email_subject = "AKS Pod Restart Alert"
#   }

#   data_source_id = azurerm_log_analytics_workspace.aks.id
#   description    = "Alert when pods are restarting frequently"
#   enabled        = true

#   query       = <<-QUERY
#     KubePodInventory
#     | where ContainerRestartCount > 5
#     | summarize AggregatedValue = count() by Name
#   QUERY
#   frequency   = 5
#   time_window = 30

#   trigger {
#     operator  = "GreaterThan"
#     threshold = 0
#   }
# }

# resource "azurerm_monitor_metric_alert" "api_response_time" {
#   name                = "api-response-time-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_application_insights.api.id]

#   criteria {
#     metric_namespace = "microsoft.insights/components"
#     metric_name      = "requests/duration"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 1000 # 1 second
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.aks_alerts.id
#   }
# }

# resource "azurerm_monitor_metric_alert" "api_failure_rate" {
#   name                = "api-failure-rate-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_application_insights.api.id]

#   criteria {
#     metric_namespace = "microsoft.insights/components"
#     metric_name      = "requests/failed"
#     aggregation      = "Count"
#     operator         = "GreaterThan"
#     threshold        = 10
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.aks_alerts.id
#   }
# }

# resource "azurerm_monitor_scheduled_query_rules_alert" "api_error_alert" {
#   name                = "api-error-alert"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name

#   action {
#     action_group  = [azurerm_monitor_action_group.aks_alerts.id]
#     email_subject = "API Error Alert"
#   }

#   data_source_id = azurerm_application_insights.api.id
#   description    = "Alert when API logs show a high number of errors"
#   enabled        = true

#   query       = <<-QUERY
#     requests
#     | where resultCode >= 500
#     | summarize ErrorCount = count() by bin(timestamp, 5m)
#     | where ErrorCount > 10
#   QUERY
#   frequency   = 5
#   time_window = 30

#   trigger {
#     operator  = "GreaterThan"
#     threshold = 0
#   }
# }
