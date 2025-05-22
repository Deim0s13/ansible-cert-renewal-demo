# The full Azure resource ID of the virtual machine
output "vm_id" {
  description = "The ID of the Linux virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

# The internal private IP of the VM (for SSH or service access)
output "private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic.private_ip_address
}