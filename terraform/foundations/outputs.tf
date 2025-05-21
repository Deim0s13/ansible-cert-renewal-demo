##########################################
# Outputs for the Azure demo environment
# These expose important values post-deployment
##########################################

# Public IP address assigned to the RHEL 9 Jump Host
# This can be used to verify connection setup in the Azure Portal
output "jump_host_ip" {
  value = azurerm_public_ip.jump.ip_address
}