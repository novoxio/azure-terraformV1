# variables.tf

variable "region" {
  description = "Azure region where resources will be created."
  type        = string
  default     = "Norway East"  # Endre hvis nødvendig
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "network_id" {
  description = "ID of the subnet to which the VM NIC will connect."
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine."
  type        = string
  default     = "Standard_B1ms"
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}

variable "db_backend_pool_id" {
  description = "ID of the backend address pool for the database load balancer"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key"
  default     = "C:/Users/tzcra/Documents/azure-terraform/terraform_key"
}