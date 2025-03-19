# resource "azurerm_monitor_diagnostic_setting" "aks" {
#   name                       = "${azurerm_kubernetes_cluster.capstone.name}-diag"
#   target_resource_id         = azurerm_kubernetes_cluster.capstone.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_workspace.id

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

#   depends_on = [azurerm_kubernetes_cluster.capstone, azurerm_log_analytics_workspace.aks_workspace]
# }

resource "azurerm_log_analytics_workspace" "aks_workspace" {
  name                = "${var.rg_name}-log-analytics"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"

  retention_in_days = 30

  depends_on = [azurerm_resource_group.aks_rg]
}

resource "azurerm_application_insights" "api" {
  name                = "api-appinsights"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  application_type    = "web"

  depends_on = [azurerm_resource_group.aks_rg]
}

output "instrumentation_key" {
  value     = azurerm_application_insights.api.instrumentation_key
  sensitive = true
}

# Availability Test for the API endpoint
resource "azurerm_application_insights_web_test" "api_test" {
  name                    = "time-api-availability-test"
  location                = azurerm_resource_group.aks_rg.location
  resource_group_name     = azurerm_resource_group.aks_rg.name
  application_insights_id = azurerm_application_insights.api.id
  kind                    = "ping"
  frequency               = 300 # 5 minutes
  timeout                 = 120 # 2 minutes
  enabled                 = true
  geo_locations           = ["us-ca-sjc-azr", "us-tx-sn1-azr", "us-il-ch1-azr"]

  configuration = <<XML
<WebTest Name="TimeAPIAvailabilityTest" Enabled="True" Timeout="120" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010">
  <Items>
    <Request Method="GET" Version="1.1" Url="https://api.mywonder.works/time" />
  </Items>
</WebTest>
XML

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [
    azurerm_application_insights.api,
    kubernetes_ingress_v1.time_api,
    module.certmanager
  ]
}

# Dashboard for Time API monitoring
resource "azurerm_portal_dashboard" "time_api_dashboard" {
  name                = "time-api-dashboard"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  tags = {
    source = "terraform"
  }

  dashboard_properties = <<DASH
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": "${azurerm_application_insights.api.id}"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "requests | where name startswith 'GET /time' | summarize count() by bin(timestamp, 5m), resultCode",
                "ControlType": "FrameControlChart",
                "SpecificChart": "Line"
              }
            }
          }
        }
      }
    }
  }
}
DASH

  depends_on = [
    azurerm_application_insights.api,
    azurerm_log_analytics_workspace.aks_workspace,
    kubernetes_deployment.time_api,
    kubernetes_service.time_api
  ]
}