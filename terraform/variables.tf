# This file contains the variables that will be used in the main.tf file

variable "region" {
  description = "The location/region of the resource group"
  type        = string
  default     = "eastus"
}

# variable "workstation_IP_address" {
#   description = "The IP address of the workstation"
#   type        = string
# }

variable "my_user_object_id" {
  description = "The object id of the user"
  type        = string
}

variable "namecom_username" {
  description = "Name.com API username"
  type        = string
  sensitive   = true
}

variable "namecom_token" {
  description = "Name.com API token"
  type        = string
  sensitive   = true
}