# ───────────────────────────────────
# Shared Variables for All VMs
# Supports both Linux and Windows modules
# ───────────────────────────────────

variable "location" {
  description = "The Azure region where all VMs will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Azure resource group to deploy resources into"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet used by all VMs"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix added to unique resource names like hostnames or DNS"
  type        = string
}

# ───────────────────────────────────
# Network Security Group IDs
# ───────────────────────────────────

variable "linux_nsg_id" {
  description = "The ID of the shared NSG used by Linux-based VMs"
  type        = string
}

variable "windows_nsg_id" {
  description = "The ID of the shared NSG used by Windows-based VMs"
  type        = string
}

# ───────────────────────────────────
# Linux-Specific Inputs
# ───────────────────────────────────

variable "admin_ssh_public_key" {
  description = "The SSH public key used for accessing Linux VMs"
  type        = string
}

# ───────────────────────────────────
# Optional Defaults for All VMs (Extendable)
# ───────────────────────────────────

variable "default_vm_size_linux" {
  description = "Default VM size for Linux-based VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "default_vm_size_windows" {
  description = "Default VM size for Windows-based VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "default_disk_size_gb" {
  description = "Default size (in GB) of the OS disk for all VMs"
  type        = number
  default     = 64
}

# ───────────────────────────────────
# Windows-Specific Inputs
# ───────────────────────────────────

variable "admin_username" {
  description = "The local administrator username for Windows VMs"
  type        = string
}

variable "admin_password" {
  description = "The local administrator password for Windows VMs"
  type        = string
  sensitive   = true
}
