# ───────────────────────────────────
# Name of the VM and related resources
# ───────────────────────────────────
variable "name" {
  description = "Name of the Linux VM (used as prefix for resources)"
  type        = string
}

# ───────────────────────────────────
# Azure region for the deployment
# ───────────────────────────────────
variable "location" {
  description = "Azure region"
  type        = string
}

# ───────────────────────────────────
# Resource group where the VM and NIC will be created
# ───────────────────────────────────
variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

# ───────────────────────────────────
# Static private IP address for the NIC
# ───────────────────────────────────
variable "ip_address" {
  description = "Static private IP address for the VM"
  type        = string
}

# ───────────────────────────────────
# Subnet to attach the NIC to
# ───────────────────────────────────
variable "subnet_id" {
  description = "Subnet ID to which this VM will connect"
  type        = string
}

# ───────────────────────────────────
# Pre-created NSG from foundations to associate with NIC
# ───────────────────────────────────
variable "nsg_id" {
  description = "ID of the shared Network Security Group to associate with NIC"
  type        = string
}

# ───────────────────────────────────
# SSH public key used for authentication
# ───────────────────────────────────
variable "admin_username" {
  description = "Username for the admin user"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "Public SSH key for the admin user"
  type        = string
}

# ───────────────────────────────────
# VM size (default is cost-efficient B-series)
# ───────────────────────────────────
variable "vm_size" {
  description = "VM size for the Linux instance"
  type        = string
  default     = "Standard_B1s"
}

# ───────────────────────────────────
# OS disk size in GB
# ───────────────────────────────────
variable "disk_size_gb" {
  description = "OS disk size in GB (optional)"
  type        = number
  default     = null
}

# ───────────────────────────────────
# **NEW** Optional data-disk size
# ───────────────────────────────────
variable "data_disk_size_gb" {
  description = "Size of an additional managed disk (GB). 0 = no data disk"
  type        = number
  default     = 0
}
