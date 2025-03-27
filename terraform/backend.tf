# This file is used to configure the backend for the terraform state file.
terraform {
  backend "azurerm" {
    resource_group_name  = "${random_pet.time_api.id}-backend-rg"
    storage_account_name = "bunnybackend349"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate"
  }
}