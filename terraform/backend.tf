# This file is used to configure the backend for the terraform state file.
terraform {
  backend "azurerm" {
    resource_group_name  = "backend-rg"
    storage_account_name = "bunnybackend319"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate"
  }
}