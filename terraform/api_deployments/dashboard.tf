# # You can use the grafana provider to create dashboards
# # This requires configuring the Grafana provider first
# provider "grafana" {
#   url  = azurerm_dashboard_grafana.aks_grafana.endpoint
#   auth = "${azurerm_dashboard_grafana.timeapi_grafana.api_key}"
# }

# resource "grafana_dashboard" "port_80_monitoring" {
#   config_json = file("${path.module}/dashboards/port_80_monitoring.json")
# }