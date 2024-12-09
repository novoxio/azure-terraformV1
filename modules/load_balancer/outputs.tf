output "db_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.db_backend_pool.id
}

output "db_load_balancer_public_ip" {
  value       = azurerm_public_ip.db_public_ip.ip_address
  description = "The public IP address of the database Load Balancer"
}