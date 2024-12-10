# Create Resource Group
resource "azurerm_resource_group" "my_resource_group" {
  name     = "my-resource-group"
  location = "Norway East"  # Change region to Norway East
}

# Network module
module "network" {
  source              = "./modules/network"
  region              = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
}

# Load Balancer module
module "load_balancer" {
  source              = "./modules/load_balancer"
  region              = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  vm_ids              = concat(module.vm.vm_ids)
}

# VM module
module "vm" {
  source              = "./modules/vm"
  region              = azurerm_resource_group.my_resource_group.location
  vm_size             = var.vm_size
  resource_group_name = azurerm_resource_group.my_resource_group.name
  network_id          = module.network.subnet_id
  db_backend_pool_id  = module.load_balancer.db_backend_pool_id
  admin_username      = var.admin_username      
  admin_password      = var.admin_password      
}


