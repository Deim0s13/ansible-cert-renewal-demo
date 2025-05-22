##########################################
# RHEL Web Server VM
# - Private IP only
# - Shared Linux NSG
# - Uses tags and SSH key from variables
##########################################

# NIC for rhel-web VM
resource "azurerm_network_interface" "rhel_web" {
  name                = "rhel-web-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
  }

  tags = {
    role        = "rhel-web"
    managed_by  = "terraform"
    environment = "demo"
  }
}

# Associate shared Linux NSG to this NIC
resource "azurerm_network_interface_security_group_association" "rhel_web" {
  network_interface_id      = azurerm_network_interface.rhel_web.id
  network_security_group_id = var.linux_nsg_id
}

# RHEL Web Server VM
resource "azurerm_linux_virtual_machine" "rhel_web" {
  name                = "rhel-web"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "rheluser"
  network_interface_ids = [
    azurerm_network_interface.rhel_web.id,
  ]
  disable_password_authentication = true

  os_disk {
    name                 = "rhel-web-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "rheluser"
    public_key = var.admin_ssh_public_key
  }

  tags = {
    role        = "rhel-web"
    managed_by  = "terraform"
    environment = "demo"
  }
}