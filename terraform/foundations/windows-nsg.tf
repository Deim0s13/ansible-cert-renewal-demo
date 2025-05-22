##########################################
# Shared NSG for Windows-based VMs
# - Used by: win-web, ad-pki
# - Allows RDP, HTTP, and optional domain services
##########################################

resource "azurerm_network_security_group" "windows" {
  name                = "windows-vm-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_resource_group.main]

  security_rule {
    name                       = "AllowRDPFromJumpHost"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.1.10" # jump host IP
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
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowLDAPAndKerberos"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["389", "636", "88", "464"]
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    role        = "nsg-windows"
    managed_by  = "terraform"
    environment = "demo"
  }
}