# variables.tf

variable "region" {
  description = "The Azure region to deploy resources"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "admin_username" {
  description = "Admin username for virtual machines"
  type        = string
}

variable "admin_password" {
  description = "Admin password for virtual machines"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {
    environment = "production"
    team        = "devops"
  }
}