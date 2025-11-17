# Provider configuration for runner infrastructure
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstate${random_string.storage_suffix.result}"
    container_name       = "tfstate"
    key                  = "runner-infra.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
