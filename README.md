# Ansible-Based Certificate Renewal Automation Demo

## Project Overview

### Purpose

This project demonstrates a **fully automated, self-healing certificate renewal solution** using:

- **Ansible Automation Platform (AAP)**
- **Event-Driven Ansible (EDA)**
- **Microsoft PKI (AD CS)**
- **ServiceNow for ITSM integration**

All built with **Terraform**, **Ansible**, and GitOps best practices, deployable on Azure.

---

## Architecture & Components

| Component              | Role / Function                                      |
|------------------------|------------------------------------------------------|
| **Jump Host (RHEL)**   | Central control node for Ansible/AAP provisioning    |
| **AAP Node**           | Hosts Ansible Automation Platform                    |
| **Windows AD + PKI**   | Acts as Domain Controller and Certificate Authority  |
| **Windows Web Server** | IIS-based demo site for SSL automation               |
| **RHEL Web Server**    | Apache/Nginx-based demo for SSL renewal              |
| **ServiceNow**         | Triggers cert renewal via webhooks / approvals       |
| **EDA Controller**     | Automates workflows on expiry / alerts               |

---

## Provisioning Workflow

### Step-by-Step Automation Flow

1. **Run `build-demo.sh`**
   - Creates all Azure infrastructure (NSGs, VNet, subnet, IPs, VMs)
   - Injects secrets and config from `secrets/` and outputs
2. **Jump Host Bootstrapping**
   - Cloud-init installs Python and preps VM
   - Terraform remote-exec installs Ansible automatically
3. **Post-Provisioning with Ansible (Next Phase)**
   - AAP provisioned via playbook from the jump host
   - AD + PKI domain services installed
   - SSL certificate logic deployed and automated

---

## Terraform Structure

```text
terraform/
├── foundations/          # VNet, Subnet, NSGs, Jump Host
│   ├── main.tf
│   ├── linux-nsg.tf
│   ├── windows-nsg.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars (optional)
├── vms/                  # AAP, AD/PKI, Web Servers
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars (optional)
├── modules/              # Reusable Linux and Windows VM modules
│   ├── linux-vm/
│   └── windows-vm/
└── secrets/
    └── windows-admin.b64  # Base64 encoded admin password
```

---

## Scripts

### `build-demo.sh`

Automates the full deployment of the demo environment:

- **Reads secrets**: Decodes base64 Windows admin password from `secrets/`
- **Fetches Terraform outputs** from the `foundations` layer:
  - `subnet_id`, `linux_nsg_id`, `windows_nsg_id`
- **Injects runtime variables**:
  - SSH key (`~/.ssh/ansible-demo-key.pub`)
  - Admin username/password
  - Region, resource group, suffix
- **Executes `terraform init` and `apply`** in both `foundations/` and `vms/`
  - Subscription-safe: checks active subscription ID before continuing

> Run this to deploy everything required for the demo in one step.

---

### `destroy-demo.sh`

Safely destroys the deployed environment:

- **Two-phase destruction**:
  1. Destroys the VM layer (`vms/`)
  2. Then tears down networking and jump host (`foundations/`)
    - Includes logic to decode the Windows password
    - Includes `--cleanup` flag:
    - Removes `.terraform`, `terraform.tfstate`, and `.backup` files for fresh use

> Run this when switching Azure subscriptions or after demo use.

---

### `reset-demo.sh`

  Optional utility script to clean all local state:

- Removes `.terraform/`, `.terraform.lock.hcl`, and state files from both Terraform directories
- Useful when switching to a new Azure subscription

```bash
./reset-demo.sh
```

    ---

## Git & State Hygiene

This project is designed for **short-lived cloud environments** and **frequent re-creation**:

✅ Subscription-agnostic
✅ Reset scripts included for switching Azure subscriptions
✅ SSH keys and admin secrets injected at runtime
✅ `.gitignore` protects sensitive and transient files
✅ Modular Terraform structure and reusable Ansible playbooks

---

## Coming Soon: Ansible Automation Phase

| Phase             | Action                                                  |
|-------------------|----------------------------------------------------------|
| ✅ Provision Infra | Terraform builds networking + VMs                        |
| ✅ Install Ansible | Ansible is installed on the Jump Host automatically      |
| ⏳ Install AAP     | AAP installed via playbook from Jump Host                |
| ⏳ Configure PKI   | AD Domain and Certificate Authority setup via AAP       |
| ⏳ Setup Cert Flow | Renew, validate, and bind SSL certs to services         |
| ⏳ Integrate SNOW  | Trigger certificate renewals via ServiceNow or webhook  |
| ⏳ Event Driven    | EDA automates flow based on cert expiry or alerts       |

---

## Final Notes

- Designed to work with **48-hour rotating Azure subscriptions**
- Scripts will detect mismatched state and prevent cross-subscription conflicts
- `reset-demo.sh` removes stale Terraform data to avoid errors
- Fully source-controlled and structured for **collaborative re-use**

---

*Next step: Create the Ansible playbook to install AAP from the Jump Host.*
