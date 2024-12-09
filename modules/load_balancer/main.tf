# Load Balancer Resource
resource "azurerm_lb" "db_lb" {
  name                = "db-load-balancer"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip-db"
    public_ip_address_id = azurerm_public_ip.db_public_ip.id
  }
}

# Public IP Address for Load Balancer (for Database VMs)
resource "azurerm_public_ip" "db_public_ip" {
  name                = "db-lb-public-ip"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Backend Pool for Load Balancer (for Database VMs)
resource "azurerm_lb_backend_address_pool" "db_backend_pool" {
  name            = "db-backend-pool"
  loadbalancer_id = azurerm_lb.db_lb.id
}

# Health Probe for Load Balancer (check if Database VMs are healthy)
resource "azurerm_lb_probe" "db_health_probe" {
  name            = "db-health-probe"
  loadbalancer_id = azurerm_lb.db_lb.id
  protocol        = "Tcp"
  port            = 3306 # Adjust for your database port
}

# Load Balancer Rule (Distributes traffic to Database VMs)
resource "azurerm_lb_rule" "db_lb_rule" {
  name                           = "db-load-balancer-rule"
  loadbalancer_id                = azurerm_lb.db_lb.id
  frontend_ip_configuration_name = "frontend-ip-db"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.db_backend_pool.id]
  probe_id                       = azurerm_lb_probe.db_health_probe.id
  frontend_port                  = 3306 # Adjust for your database port
  backend_port                   = 3306
  protocol                       = "Tcp"
}
