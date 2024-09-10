# This file contains the variables that will be used in the main.tf file
variable "rg_name" {
  description = "The name of the resource group"
  type        = string
  default     = "k8s-cluster-rg"
}

variable "region" {
  description = "The location/region of the resource group"
  type        = string
  default     = "southafricanorth"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "timeapi-cluster"
}

variable "allowed_source_addresses" {
  description = "List of authorized ip addresses"
  type        = list(string)
}

variable "my_user_object_id" {
  description = "The object id of the user"
  type        = string
}