# Output the VM resource ID
output "vm_id" {
  description = "The ID of the Windows virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

# Output the internal private IP of the Windows VM
output "private_ip" {
  description = "The private IP address of the Windows VM"
  value       = azurerm_network_interface.nic.private_ip_address
}