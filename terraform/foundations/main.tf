# ───────────────────────────────────
# Azure Provider Configuration is in versions.tf
# This file defines the core networking and infrastructure for the demo environment
# ───────────────────────────────────

# ───────────────────────────────────
# Create a resource group to hold all demo resources
# ───────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# ───────────────────────────────────
# Create virtual network with a /16 addresss space
# ───────────────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "cert-net"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# ───────────────────────────────────
# create the main subnet where demo VMs will reside
# ───────────────────────────────────
resource "azurerm_subnet" "main" {
  name                 = "cert-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ───────────────────────────────────
# RHEL Jump Host VM (Direct SSH Access)
# ───────────────────────────────────

resource "azurerm_network_interface" "jump" {
  name                = "jump-host-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.jump.id
  }
}

resource "azurerm_public_ip" "jump" {
  name                = "jump-host-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_linux_virtual_machine" "jump" {
  name                = "jump-host"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s" # Low-cost VM
  admin_username      = "rheluser"
  network_interface_ids = [
    azurerm_network_interface.jump.id,
  ]
  disable_password_authentication = true

  os_disk {
    name                 = "jump-host-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
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
    role = "jump-host"
  }
}

# ───────────────────────────────────
# Network Security Group (NSG) for Jump Host
# Allows inbound SSH (port 22) from any source temporarily
# In production, this should be restricted or replaced with VPN or Bastion
# ───────────────────────────────────

resource "azurerm_network_security_group" "jump" {
  name                = "jump-host-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSHFromAnywhere"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"  # Accept from any source port
    destination_port_range     = "22" # SSH port
    source_address_prefix      = "*"  # Allow from all IPs
    destination_address_prefix = "*"  # Applies to this NIC
  }

  tags = {
    role = "nsg-jump"
  }
}

# ───────────────────────────────────
# Associate NSG with Jump Host NIC
# ───────────────────────────────────

resource "azurerm_network_interface_security_group_association" "jump" {
  network_interface_id      = azurerm_network_interface.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

# ───────────────────────────────────
# Remote Execution: Install Ansible on Jump Host
# This uses Terraform's null_resource and remote-exec provisioner
# to SSH into the jump host and install Ansible automatically.
# ───────────────────────────────────

resource "null_resource" "install_ansible_on_jump" {
  # Ensure the jump host is created before this runs
  depends_on = [azurerm_linux_virtual_machine.jump]

  # Define SSH connection settings for the remote provisioner
  connection {
    type        = "ssh"
    host        = azurerm_public_ip.jump.ip_address # Use the public IP of the jump host
    user        = "rheluser"                        # Admin username configured in VM module
    private_key = file("~/.ssh/ansible-demo-key")   # Path to your SSH private key
  }

  # Inline remote commands to install Ansible using dnf
  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying VM readiness...'",
      "sleep 15",
      "sudo dnf upgrade -y",
      "echo 'Installing Ansible Core...'",
      "sudo dnf install -y ansible-core",
      "echo 'Verifying Ansible install:'",
      "ansible --version || echo 'Ansible not installed correctly'"
    ]
  }
}
