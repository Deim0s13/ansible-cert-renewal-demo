# modules/linux-vm/main.tf

# ───────────────────────────────────
# Linux VM Module
# - NIC with static IP
# - Attaches to shared NSG
# - SSH key login only
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

# ───────────────────────────────────
# Attach shared NSG to NIC
# ───────────────────────────────────
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nsg_id
}

# ───────────────────────────────────
# Define the VM
# ───────────────────────────────────
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  disable_password_authentication = true
  admin_username                  = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb != null ? var.disk_size_gb : null
  }

  dynamic "data_disk" {
    for_each = var.data_disk_size_gb > 0 ? [1] : []

    content {
      lun                  = 0
      caching              = "ReadOnly"
      storage_account_type = "Standard_LRS"
      disk_size_gb         = var.data_disk_size_gb
    }
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  custom_data = var.name == "jump-host" ? filebase64("${path.module}/jump-cloud-init.yaml") : null

  tags = {
    role        = var.name
    environment = "demo"
    managed_by  = "terraform"
  }
}
