# modules/load_balancer/variables.tf

variable "region" {
  description = "The Azure region to deploy the load balancer"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "vm_ids" {
  description = "The IDs of the VMs that will be behind the load balancer"
  type        = list(string)
}
