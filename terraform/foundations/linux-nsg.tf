##########################################
# Shared Network Security Group for Linux VMs
# - Used by rhel-web, AAP, etc.
# - Allows SSH and optional HTTP
# - Attached to each Linux NIC
##########################################

resource "azurerm_network_security_group" "linux" {
  name                = "linux-vm-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSHFromJumpHost"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.10"  # Jump host IP
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPFromVNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"  # Entire subnet
    destination_address_prefix = "*"
  }

  tags = {
    role        = "nsg-linux"
    managed_by  = "terraform"
    environment = "demo"
  }
}