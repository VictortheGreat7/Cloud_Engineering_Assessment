# This file contains defines some output requests to the Time API Azure Kubernetes Infrastructure.

output "aks_resource_group" {
  value = azurerm_resource_group.time_api_rg.name
}

output "natgtw_ip" {
  value = azurerm_public_ip.time_api_public_ip
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.time_api_cluster.name
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config
  sensitive = true
}

output "ingress_ip" {
  value = data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
}
