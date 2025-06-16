# ───────────────────────────────────
# Windows VM Module
# - NIC with static IP
# - Attaches to shared NSG
# - Local admin user with secure password
# ───────────────────────────────────

# Create NIC
resource "azurerm_network_interface" "nic" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ip_address
  }

  tags = {
    role        = var.name
    environment = "demo"
    managed_by  = "terraform"
  }
}

# Attach shared NSG to NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nsg_id
}

# Define the Windows VM
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb != null ? var.disk_size_gb : null
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  tags = {
    role        = var.name
    environment = "demo"
    managed_by  = "terraform"
  }
}
