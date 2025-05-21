##########################################
# Azure Provider Configuration is in versions.tf
# This file defines the core networking and infrastructure for the demo environment
##########################################

# Create a resource group to hold all demo resources
resource "azurerm_resource_group" "main" {
    name                    = var.resource_group_name
    location                = var.location
}

# Create virtual network with a /16 addresss space
resource "azurerm_virtual_network" "main" {
    name                    = "cert-net"
    address_space           = ["10.0.0.0/16"]
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name
}

# create the main subnet where demo VMs will reside
resource "azurerm_subnet" "main" {
    name                    = "cert-subnet"
    resource_group_name     = azurerm_resource_group.main.name
    virtual_network_name    = azurerm_virtual_network.main.name
    address_prefixes        = ["10.0.0.1/24"]
}

# Create a dedicate subnet for Azure Bastion (must be name exactly as below)
resource "azurerm_subnet" "bastion" {
    name                    = "AzureBastionSubnet" # Required name
    resource_group_name     = azurerm_resource_group.main.name
    virtual_network_name    = azurerm_virtual_network.main.name
    address_prefixes        = ["10.0.2.0/27"] # Small range, only need for Bastion
}

# Public IP address for the Bastion (so we can connect to the private VMs)
resource "azurerm_public_ip" "bastion" {
    name                    = "bastion-public-ip"
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name
    allocation_method       = "Static" # Required for Bastion
    sku                     = "Standard" # Required for Bastion
}

# Azure Bastion host to allow secure RDP/SSH into private VMs via the Azure Portal
resource "azurerm_bastion_host" "main" {
    name                    = "cert-bastion"
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name

    ip_configuration {
      name                  = "Bastion-ip-config"
      subnet_id             = azurerm_subnet.bastion.id
      public_ip_address_id  = azurerm_public_ip.bastion.id
    }  
}