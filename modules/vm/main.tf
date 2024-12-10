# Webserver VM
resource "azurerm_virtual_machine" "web_vm" {
  name                  = "web-vm"
  location              = var.region
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.web_nic.id]
  vm_size               = var.vm_size

  # OS Disk Configuration
  storage_os_disk {
    name              = "webosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Image Reference (Ubuntu 18.04-LTS)
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # OS Profile Configuration (admin credentials)
  os_profile {
    computer_name  = "web-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  # Linux-specific configuration
  os_profile_linux_config {
    disable_password_authentication = false
  }

  # Tags for the VM
  tags = var.tags
}

# Web VM Custom Script Extension
resource "azurerm_virtual_machine_extension" "web_install" {
  name                  = "install-web-tools"
  virtual_machine_id    = azurerm_virtual_machine.web_vm.id
  publisher             = "Microsoft.Azure.Extensions"
  type                  = "CustomScript"
  type_handler_version  = "2.1"
  
  settings = jsonencode({
    script = filebase64("modules/vm/cloud-init-web.sh")

  })
}

# Database VMs (2 instances)
resource "azurerm_virtual_machine" "db_vm" {
  count                 = 2
  name                  = "db-vm-${count.index + 1}"
  location              = var.region
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.db_nic[count.index].id]
  vm_size               = var.vm_size

  # OS Disk Configuration
  storage_os_disk {
    name              = "dbosdisk-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Image Reference (Ubuntu 18.04-LTS)
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # OS Profile Configuration (admin credentials)
  os_profile {
    computer_name  = "db-vm-${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  # Linux-specific configuration
  os_profile_linux_config {
    disable_password_authentication = false
  }

  # Tags for the VM
  tags = var.tags
}

# Database VM Custom Script Extension
resource "azurerm_virtual_machine_extension" "db_install" {
  count                 = 2
  name                  = "mysql-setup-${count.index + 1}"
  virtual_machine_id    = azurerm_virtual_machine.db_vm[count.index].id
  publisher             = "Microsoft.Azure.Extensions"
  type                  = "CustomScript"
  type_handler_version  = "2.1"
  
  settings = jsonencode({
    script = filebase64("modules/vm/cloud-init-mysql.sh")
  })
}
# Web VM Network Interface
resource "azurerm_network_interface" "web_nic" {
  name                 = "web-nic"
  location             = var.region
  resource_group_name  = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.network_id  # Replace with actual subnet ID
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}

# Web VM Network Security Group
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = var.region
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with existing Web NIC
resource "azurerm_network_interface_security_group_association" "web_nic_nsg" {
  network_interface_id      = azurerm_network_interface.web_nic.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}
# Public IP for Web VM
resource "azurerm_public_ip" "web_public_ip" {
  name                = "web-public-ip"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU requires Static IP
}

# Database VM Network Interfaces (2 instances)
resource "azurerm_network_interface" "db_nic" {
  count                = 2
  name                 = "db-nic-${count.index + 1}"
  location             = var.region
  resource_group_name  = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.network_id  # Replace with actual subnet ID
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NICs with Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "db_nic_pool_association" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.db_nic[count.index].id
  backend_address_pool_id = var.db_backend_pool_id
  ip_configuration_name   = azurerm_network_interface.db_nic[count.index].ip_configuration[0].name
}
