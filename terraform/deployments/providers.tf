# This file is used to define the providers for the terraform configuration.

terraform {
  required_providers {
    azuread = ">= 2.9.0"
    azurerm = ">= 3.0.0"
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "d31507f4-324c-4bd1-abe1-5cdf45cba77d"
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].host
  username               = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].username
  password               = azurerm_kubernetes_cluster.capstone.kube_admin_config[0].password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config[0].cluster_ca_certificate)
}
