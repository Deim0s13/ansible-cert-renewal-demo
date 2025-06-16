# ───────────────────────────────────
# Main Terraform File for All VMs
# - Uses reusable modules
# ───────────────────────────────────

# ───────────────────────────────────
# RHEL Web Server (Apache/Nginx demo site)
# ───────────────────────────────────
module "rhel_web" {
  source               = "../modules/linux-vm"
  name                 = "rhel-web"
  ip_address           = "10.0.1.11"
  subnet_id            = var.subnet_id
  nsg_id               = var.linux_nsg_id
  location             = var.location
  resource_group_name  = var.resource_group_name
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key
}

# ───────────────────────────────────
# Ansible Automation Platform Controller
# ───────────────────────────────────
module "aap" {
  source               = "../modules/linux-vm"
  name                 = "aap"
  ip_address           = "10.0.1.12"
  subnet_id            = var.subnet_id
  nsg_id               = var.linux_nsg_id
  location             = var.location
  resource_group_name  = var.resource_group_name
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key
}

# ───────────────────────────────────
# Windows Web Server (IIS with certs)
# ───────────────────────────────────
module "win_web" {
  source              = "../modules/windows-vm"
  name                = "win-web"
  ip_address          = "10.0.1.13"
  subnet_id           = var.subnet_id
  nsg_id              = var.windows_nsg_id
  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}

# ───────────────────────────────────
# AD + PKI Server (Domain Controller and Certificate Authority)
# ───────────────────────────────────
module "ad_pki" {
  source              = "../modules/windows-vm"
  name                = "ad-pki"
  ip_address          = "10.0.1.14"
  subnet_id           = var.subnet_id
  nsg_id              = var.windows_nsg_id
  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}
