# Ansible-Based Certificate Renewal Automation Demo

## Project Overview

### Purpose

This project demonstrates a **fully automated, self-healing certificate renewal solution** using:

- **Ansible Automation Platform (AAP)**
- **Event-Driven Ansible (EDA)**
- **Microsoft PKI (AD CS)**
- **ServiceNow for ITSM integration**

All built with **Terraform**, **Ansible**, and best-practice GitOps, deployable on Azure.

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
   - Cloud-init installs Python, sets hostname, prepares for Ansible
   - Remote-exec installs Ansible
3. **Post-Provisioning with Ansible (Coming Next)**
   - AAP provisioned from the Jump Host
   - AD + PKI configured
   - SSL cert automation setup

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
    └── windows-admin.b64 # Base64 encoded admin password (optional)

    ---

    ## Build & Destroy Scripts

    ### `build-demo.sh`

    Automates the full deployment of the demo environment:

    - **Reads secrets**: Automatically decodes a base64-encoded admin password from `secrets/windows-admin.b64`
    - **Fetches Terraform outputs** from the `foundations` layer:
      - `subnet_id`
      - `linux_nsg_id`
      - `windows_nsg_id`
    - **Injects runtime variables** including:
      - SSH key (`~/.ssh/ansible-demo-key.pub`)
      - Admin username/password
      - Location, resource group, and suffix
    - **Runs `terraform init` and `terraform apply`** in the `vms/` folder
    - Designed to be reusable across any subscription (no hardcoded IDs)

    > Fully automated: one command builds out your Azure infrastructure, including networking, NSGs, VMs, and provisioning logic.

    ---

    ### `destroy-demo.sh`

    Handles the safe teardown of all deployed resources:

    - **Two-phase destruction**:
      1. Destroys VMs via `terraform destroy` in `vms/`
      2. Then destroys networking and core infra from `foundations/`
    - Optional `--cleanup` flag:
      - Deletes `.terraform/`, `terraform.tfstate`, and `terraform.tfstate.backup` for both folders
      - Prevents stale state issues across re-used environments
    - Includes basic checks for missing output or credentials

    > Designed for safe teardown between short-lived Azure trial subscriptions or daily rebuilds.

    ---

    ## State Agnosticism & Portability

    To ensure the environment works across **rotating Azure subscriptions** or fresh setups:

    - No hardcoded subscription IDs
    - Secrets stored in base64 (not plaintext)
    - All secrets, NSGs, and subnet references pulled dynamically via `terraform output`
    - Git-tracked configuration and secure `.gitignore` templates
    - All provisioning is initiated through scripts — no manual CLI steps required

    ---

    ## Coming Next: Ansible Automation Phase

    | Phase            | Action                                        |
    |------------------|-----------------------------------------------|
    | ✅Provision Infra | Terraform builds networking + VMs             |
    | ⏳ Install AAP    | Via Ansible from Jump Host                    |
    | ⏳ Configure PKI  | Install and configure AD Domain + Certificate Authority |
    | ⏳ Setup Cert Flow| Renew, validate, install, and log SSL certs  |
    | ⏳ Integrate SNOW | Trigger flows via ServiceNow or webhook       |
    | ⏳ Event Driven   | Use Event-Driven Ansible to enable self-healing |

    > Next phase will use the Jump Host as the Ansible control node to fully automate the AAP, Windows PKI, and SSL management setup.
