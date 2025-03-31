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

# Output the ingress IP for reference
output "ingress_ip" {
  value = data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
}

# Output the name servers - you'll need these to update your domain registrar
output "name_servers" {
  value = azurerm_dns_zone.mywonder_works.name_servers
}
