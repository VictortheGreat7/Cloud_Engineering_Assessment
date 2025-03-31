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
