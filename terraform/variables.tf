# This file contains the variables that will be used in the main.tf file

variable "region" {
  description = "The location/region of the resource group"
  type        = string
  default     = "eastus"
}

variable "my_user_object_id" {
  description = "The object id of the user"
  type        = string
}