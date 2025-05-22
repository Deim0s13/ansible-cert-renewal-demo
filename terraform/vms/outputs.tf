##########################################
# Outputs for All VMs
# Exposes internal IPs and VM IDs from each module
##########################################

# RHEL Web Server
output "rhel_web_vm_id" {
  description = "The resource ID of the RHEL web server VM"
  value       = module.rhel_web.vm_id
}

output "rhel_web_private_ip" {
  description = "The private IP address of the RHEL web server"
  value       = module.rhel_web.private_ip
}

# Ansible Automation Platform Controller
output "aap_vm_id" {
  description = "The resource ID of the Ansible Automation Platform VM"
  value       = module.aap.vm_id
}

output "aap_private_ip" {
  description = "The private IP address of the AAP VM"
  value       = module.aap.private_ip
}

# Windows Web Server
output "win_web_vm_id" {
  description = "The resource ID of the Windows web server VM"
  value       = module.win_web.vm_id
}

output "win_web_private_ip" {
  description = "The private IP address of the Windows web server"
  value       = module.win_web.private_ip
}

# Active Directory + PKI Server
output "ad_pki_vm_id" {
  description = "The resource ID of the AD + PKI server VM"
  value       = module.ad_pki.vm_id
}

output "ad_pki_private_ip" {
  description = "The private IP address of the AD + PKI server"
  value       = module.ad_pki.private_ip
}