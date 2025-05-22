##########################################
# Shared variables reused from foundations
##########################################

# Name of the Azure Resource Group where all infrastructure will live
variable "resource_group_name" {
    type        = string
    description = "The name of the resource group used for the demo environment"
    default     = "cert-renewal-demo-rg"
}

# Azure location/region to deploy resources into (e.g., AustraliaEast, EastUS, EastAsia)
variable "location" {
    type        = string
    description = "Azure region where resources will be deployed"
    default     = "EastAsia"
}

# Random or unique string to ensure resources like Bastion DNS names don't clash
variable "random_suffix" {
    type        = string
    description = "Random suffix added to unique resource names linke DNS and hostnames"
}

# SSH public key string used to log in to VMs (passed via CLI to avoid storing in Git)
variable "admin_ssh_public_key" {
    type        = string
    description = "The SSH public key used to access the jump host"
}

##########################################
# VM-specific variables
##########################################

variable "subnet_id" {
  description = "ID of the subnet to attach VMs to"
  type        = string
}

##########################################
# Shared NSG ID used by all Linux VMs
##########################################

variable "linux_nsg_id" {
  type        = string
  description = "The Azure Resource ID of the shared Network Security Group (NSG) applied to all Linux-based VMs. This should be created in the foundations layer and passed in via CLI or script."
}