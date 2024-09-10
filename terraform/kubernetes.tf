# data "azurerm_kubernetes_cluster" "credentials" {
#   name                = azurerm_kubernetes_cluster.capstone.name
#   resource_group_name = azurerm_resource_group.aks_rg.name
# }

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].cluster_ca_certificate)
  # load_admin_config_file       = false
}