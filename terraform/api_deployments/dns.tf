# Create the DNS Zone
resource "azurerm_dns_zone" "mywonder_works" {
  name                = "mywonder.works"
  resource_group_name = azurerm_resource_group.time_api_rg.name

  tags = {
    environment = "test"
  }

  depends_on = [module.nginx-controller]
}

resource "azurerm_dns_a_record" "api" {
  name                = "api"
  zone_name           = azurerm_dns_zone.mywonder_works.name
  resource_group_name = azurerm_dns_zone.mywonder_works.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip]

  depends_on = [module.nginx-controller, data.kubernetes_service.nginx_ingress]
}

resource "azurerm_role_assignment" "agentpool_dns_zone_contributor" {
  scope                = azurerm_dns_zone.mywonder_works.id
  role_definition_name = "DNS Zone Contributor"

  principal_id = data.azurerm_kubernetes_cluster.time_api_cluster.kubelet_identity[0].object_id

  depends_on = [
    azurerm_dns_zone.mywonder_works
  ]
}

# Output the name servers - you'll need these to update your domain registrar
output "name_servers" {
  value = azurerm_dns_zone.mywonder_works.name_servers
}