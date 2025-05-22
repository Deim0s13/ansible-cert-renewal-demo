##########################################
# modules/windows-vm/variables.tf
# Variables required for deploying a Windows VM
##########################################

# Name of the Windows VM
variable "name" {
  description = "Name of the Windows VM (used as prefix for resources)"
  type        = string
}

# Azure region for the deployment
variable "location" {
  description = "Azure region"
  type        = string
}

# Resource group for the VM
variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

# Static private IP address
variable "ip_address" {
  description = "Static private IP address for the VM"
  type        = string
}

# Subnet to attach NIC to
variable "subnet_id" {
  description = "Subnet ID for the VM NIC"
  type        = string
}

# Shared NSG to attach to NIC
variable "nsg_id" {
  description = "ID of the NSG to associate with NIC"
  type        = string
}

# Admin username for Windows VM
variable "admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
}

# Admin password (sensitive)
variable "admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
}

# VM size (SKU)
variable "vm_size" {
  description = "VM size for the Windows VM"
  type        = string
  default     = "Standard_B2s"
}

# OS disk size
variable "disk_size_gb" {
  description = "Size of the OS disk in GB (optional)"
  type        = number
  default     = null
}