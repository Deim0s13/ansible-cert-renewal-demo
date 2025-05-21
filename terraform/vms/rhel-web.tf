##########################################
# RHEL Web Server VM
# - Private IP only
# - Accessible via jump host
# - Can be used for Apache/Nginx + Cert Renewal Demo
##########################################

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
}

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
    role = "rhel-web"
  }
}