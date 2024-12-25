# resource "azurerm_monitor_action_group" "email_alert" {
#   name                = "time-api-alert-action-group"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   short_name          = "APIAlerts"

#   email_receiver {
#     name          = "DevOpsTeam"
#     email_address = "greatvictor.anjorin@gmail.com"
#   }

#   depends_on = [azurerm_application_insights.api]
# }

# # CPU and Memory Alert for Time API pods
# resource "azurerm_monitor_metric_alert" "pod_cpu_alert" {
#   name                = "time-api-pod-cpu-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_kubernetes_cluster.capstone.id]
#   description         = "Alert when pod CPU usage exceeds 80%"
#   severity            = 2

#   criteria {
#     metric_namespace = "microsoft.containerservice/managedclusters"
#     metric_name      = "node_cpu_usage_percentage" # Updated metric name
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#     dimension {
#       name     = "kubernetes namespace" # Updated dimension
#       operator = "Include"
#       values   = ["default"] # Assuming your app is in default namespace
#     }
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.email_alert.id
#   }

#   depends_on = [
#     azurerm_monitor_action_group.email_alert,
#     azurerm_kubernetes_cluster.capstone,
#     kubernetes_deployment.time_api
#   ]
# }

# # Response Time Alert for Time API
# resource "azurerm_monitor_metric_alert" "response_time_alert" {
#   name                = "time-api-response-time-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_application_insights.api.id]
#   description         = "Alert when response time exceeds 1 second"
#   severity            = 2

#   criteria {
#     metric_namespace = "microsoft.insights/components"
#     metric_name      = "requests/duration"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 1000 # 1 second in milliseconds
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.email_alert.id
#   }

#   depends_on = [
#     azurerm_monitor_action_group.email_alert,
#     azurerm_application_insights.api,
#     kubernetes_service.time_api
#   ]
# }

# # Availability Alert
# resource "azurerm_monitor_metric_alert" "availability_alert" {
#   name                = "time-api-availability-alert"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   scopes              = [azurerm_application_insights.api.id]
#   description         = "Alert when availability drops below 99%"
#   severity            = 1

#   criteria {
#     metric_namespace = "microsoft.insights/components"
#     metric_name      = "availabilityResults/availabilityPercentage"
#     aggregation      = "Average"
#     operator         = "LessThan"
#     threshold        = 99
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.email_alert.id
#   }

#   depends_on = [
#     azurerm_monitor_action_group.email_alert,
#     azurerm_application_insights.api,
#     kubernetes_ingress_v1.time_api
#   ]
# }