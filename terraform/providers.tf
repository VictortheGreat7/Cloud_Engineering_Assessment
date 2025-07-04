# This file is used to define the providers for the terraform configuration.

terraform {
  required_providers {
    azuread = "3.4.0"
    azurerm = "4.34.0"
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "d31507f4-324c-4bd1-abe1-5cdf45cba77d"
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.time_api_cluster.kube_admin_config[0].cluster_ca_certificate)
}
