##########################################
# Outputs for the Azure demo environment
# These expose important values post-deployment
##########################################

# Public IP address assigned to the RHEL 9 Jump Host
# This can be used to verify connection setup in the Azure Portal
output "jump_host_ip" {
  value = azurerm_public_ip.jump.ip_address
}

##########################################
# Outputs for Foundations Layer
# - These values are passed to the VM layer
# - Used to reference shared infra like subnet and NSGs
##########################################

output "subnet_id" {
  description = "The ID of the main subnet used for VM deployment"
  value       = azurerm_subnet.main.id
}

output "linux_nsg_id" {
  description = "The ID of the shared Linux NSG used for all Linux-based VMs"
  value       = azurerm_network_security_group.linux.id
}

output "windows_nsg_id" {
  description = "The ID of the shared Windows NSG used for all Windows-based VMs"
  value       = azurerm_network_security_group.windows.id
}