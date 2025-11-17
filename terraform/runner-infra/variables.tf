# Variables for runner infrastructure

variable "resource_group_name" {
  description = "Name of the existing resource group where main infrastructure is deployed"
  type        = string
  default     = ""
}

variable "vnet_name" {
  description = "Name of the existing virtual network"
  type        = string
  default     = ""
}

variable "runner_token" {
  description = "GitHub Actions runner registration token"
  type        = string
  default     = ""
  sensitive   = true
}
