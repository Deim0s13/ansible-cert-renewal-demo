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

1. **Run `provision-demo.yml` Ansible playbook** (replaces the shell script)
   - Provisions Azure infrastructure: NSGs, VNet, subnet, IPs, VMs
   - Injects runtime config (SSH keys, passwords)
   - Uploads AAP installer and clones Git repo onto Jump Host
2. **Jump Host Bootstrapping**
   - Cloud-init sets up Ansible prerequisites
   - Ansible installs AAP and prepares automation stack
3. **Post-Provisioning with Ansible**
   - AAP installs and manages PKI and web servers
   - Certificate automation initiated via AAP and EDA

---

## Directory Structure

```text
ansible-cert-renewal-demo/
├── terraform/
│   ├── foundations/          # VNet, Subnet, NSGs, Jump Host
│   ├── vms/                  # AAP, AD/PKI, Web Servers
│   ├── modules/              # Reusable modules for VMs
│   └── secrets/              # Encoded admin credentials
├── downloads/               # AAP installer bundle
├── ansible/
│   ├── inventory/
│   │   ├── provisioning-hosts  # For local setup tasks
│   │   └── demo-hosts          # For target infrastructure
│   ├── playbooks/             # All provisioning and install playbooks
│   ├── provisioning/          # Modular provisioning logic
│   ├── roles/                 # Ansible roles (e.g., aap_install)
│   └── ansible.cfg            # Ansible configuration
└── reset-demo.sh             # Wipe local Terraform state
```

---

## Key Scripts & Playbooks

### `provision-demo.yml`

- **Main orchestration playbook**
- Runs from your laptop using `localhost`
- Modular: imports provisioning, upload, and repo clone tasks

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbooks/provision-demo.yml
```

### `reset-demo.sh`

Removes all Terraform state locally. Run this when switching Azure subscriptions.

```bash
./reset-demo.sh
```

> Avoids conflicts when Terraform state doesn't match your current subscription.
> Will look to replace this with an Ansible playbook.

---

## Git & State Hygiene

✅ Subscription-agnostic provisioning
✅ Reset scripts for clean rebuilds
✅ Secrets injected dynamically — not stored in plaintext
✅ Inventory separation for provisioning vs. demo
✅ Terraform + Ansible fully integrated

---

## Ansible Automation Phase (Current State)

| Phase              | Action                                                  |
|--------------------|----------------------------------------------------------|
| ✅ Provision Infra  | Terraform builds networking + VMs                        |
| ✅ Install Ansible  | Jump Host installs Ansible automatically                 |
| ✅ Upload Installer | AAP bundle uploaded to Jump Host                         |
| ✅ Git Clone        | Git repo cloned to Jump Host                             |
| ⏳ Install AAP      | AAP installed on dedicated node via playbook             |
| ⏳ Configure PKI    | Domain and CA services installed via Ansible             |
| ⏳ Setup Cert Flow  | Cert issuance, renewal, and binding via playbooks       |
| ⏳ ServiceNow Hook  | Cert triggers handled via ServiceNow and Webhooks        |
| ⏳ EDA Integration  | Self-healing workflows run on alert or expiry detection |

---

## Final Notes

- Designed for **short-lived Azure subscriptions**
- Modular, idempotent, and easily testable
- Replace `git_repo_url` in playbook variables to point to your own repo
- Use `--start-at-task` or `--tags` to target specific phases

> Fully open source and designed for re-use and extension
