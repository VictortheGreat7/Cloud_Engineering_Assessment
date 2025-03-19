# This file is used to define the providers for the terraform configuration.

terraform {
  required_providers {
    azuread = ">= 3.1.0"
    azurerm = ">= 4.23.0"
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1.3"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "d31507f4-324c-4bd1-abe1-5cdf45cba77d"
}

# First, convert the raw YAML string to a parsed object using yamldecode
locals {
  kube_config = yamldecode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw)
}

# Now you can reference the config elements from the parsed structure
provider "kubernetes" {
  host                   = local.kube_config.clusters[0].cluster.server
  client_certificate     = base64decode(local.kube_config.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kube_config.users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster["certificate-authority-data"])
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.clusters[0].cluster.server
    client_certificate     = base64decode(local.kube_config.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kube_config.users[0].user["client-key-data"])
    cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster["certificate-authority-data"])
  }
}

provider "kubectl" {
  host                   = local.kube_config.clusters[0].cluster.server
  client_certificate     = base64decode(local.kube_config.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kube_config.users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster["certificate-authority-data"])
}

# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.cluster_ca_certificate)
# }

# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.cluster_ca_certificate)
#   }
# }

# provider "kubectl" {
#   host                   = azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.capstone.kube_admin_config_raw.cluster_ca_certificate)
#   # load_admin_config_file       = false
# }
