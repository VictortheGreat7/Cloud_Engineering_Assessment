# resource "azurerm_application_insights" "api" {
#   name                = "api-appinsights"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   application_type    = "web"
# }

# output "instrumentation_key" {
#   value     = azurerm_application_insights.api.instrumentation_key
#   sensitive = true
# }

# resource "azurerm_log_analytics_workspace" "aks" {
#   name                = "aks-log-workspace"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

# resource "azurerm_monitor_action_group" "aks_alerts" {
#   name                = "aks-alerts"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   short_name          = "aksalerts"

#   email_receiver {
#     name          = "sendtoadmin"
#     email_address = "greatvictor.anjorin@gmail.com"
#   }

#   depends_on = [azurerm_kubernetes_cluster.capstone]
# }

# resource "azurerm_monitor_diagnostic_setting" "aks" {
#   name                       = "${azurerm_kubernetes_cluster.capstone.name}-diag"
#   target_resource_id         = azurerm_kubernetes_cluster.capstone.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

#   enabled_log {
#     category = "kube-apiserver"
#   }

#   enabled_log {
#     category = "kube-controller-manager"
#   }

#   enabled_log {
#     category = "kube-scheduler"
#   }

#   enabled_log {
#     category = "kube-audit"
#   }

#   enabled_log {
#     category = "cluster-autoscaler"
#   }

#   metric {
#     category = "AllMetrics"
#     enabled  = true
#   }

#   depends_on = [azurerm_kubernetes_cluster.capstone, azurerm_log_analytics_workspace.aks]
# }
