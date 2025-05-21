##########################################
# Outputs for the Azure demo environment
# These expose important values post-deployment
##########################################

# Public IP address assigned to the Azure Bastion Host
# This can be used to verify connection setup in the Azure Portal
output "bastion_ip" {
  description = "The public IP address of the Azure Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}