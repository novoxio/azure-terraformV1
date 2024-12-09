# modules/network/variables.tf

variable "region" {
  description = "The Azure region to deploy the network"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}
