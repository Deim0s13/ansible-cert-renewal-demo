# ───────────────────────────────────
# Input variables for the Azure demo environment
# These allow flexibility across environments or contributors
# ───────────────────────────────────

# ───────────────────────────────────
# Name of the Azure Resource Group where all infrastructure will live
# ───────────────────────────────────
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group used for the demo environment"
  default     = "cert-renewal-demo-rg"
}

# ───────────────────────────────────
# Azure location/region to deploy resources into (e.g., AustraliaEast, EastUS, EastAsia)
# ───────────────────────────────────
variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
  default     = "eastasia"
}

# ───────────────────────────────────
# Random or unique string to ensure resources like Bastion DNS names don't clash
# ───────────────────────────────────
variable "random_suffix" {
  type        = string
  description = "Random suffix added to unique resource names linke DNS and hostnames"
}

# ───────────────────────────────────
# SSH public key string used to log in to VMs (passed via CLI to avoid storing in Git)
# ───────────────────────────────────
variable "admin_ssh_public_key" {
  type        = string
  description = "The SSH public key used to access the jump host"
}
