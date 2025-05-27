# Ansible-Based Certificate Renewal Automation Demo

## Project Overview

### Purpose

This project demonstrates a **fully automated, self-healing certificate renewal solution** using:

- **Ansible Automation Platform (AAP)**
- **Event-Driven Ansible (EDA)**
- **Microsoft PKI (AD CS)**
- **ServiceNow for ITSM integration**

Provisioned on **Azure** using a **hybrid automation model**:
**Terraform & Bash** for infrastructure → **Ansible** for post-provisioning setup.

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
   - Validates Azure subscription
   - Applies Terraform for foundations (VNet, NSGs, Jump Host)
   - Applies Terraform for VM layer (AAP, AD, Web Servers)
   - Decodes secrets from base64
   - Automatically invokes Ansible for post-provisioning

2. **Post-Provisioning via Ansible**
   - Jump Host is configured and updated
   - AAP installer is uploaded to the Jump Host
   - Git repo is cloned to the Jump Host for further automation

---

## Directory Structure

```text
ansible-cert-renewal-demo/
├── terraform/
│   ├── foundations/            # VNet, Subnet, NSGs, Jump Host
│   ├── vms/                    # AAP, AD/PKI, Web Servers
│   ├── modules/                # Reusable modules for VMs
│   └── secrets/                # Encoded admin credentials
├── downloads/                  # AAP installer bundle
├── ansible/
│   ├── inventory/
│   │   └── dynamic             # Jump host IP passed in at runtime
│   ├── playbooks/
│   │   ├── post-provision.yml         # Main post-provision runner
│   │   ├── configure-jump-host.yml    # Ensures packages and updates
│   │   ├── upload-aap-installer.yml   # Uploads AAP tarball
│   │   ├── clone-repo-to-jump.yml     # Clones Git repo
│   │   └── archived/                  # Legacy playbooks (if any)
│   └── ansible.cfg
├── build-demo.sh              # Full hybrid provisioning script
├── destroy-demo.sh            # Teardown script
└── reset-demo.sh              # Terraform state cleaner
```

---

## Key Scripts & Playbooks

### `build-demo.sh`

This is the main orchestration script. It performs the following:

- Validates Azure subscription matches Terraform state
- Applies the **foundations** layer (network, NSGs, Jump Host)
- Applies the **VM layer** (AAP, AD/PKI, Web Servers)
- Automatically calls Ansible to run post-provisioning tasks

Run it like so:

```bash
./build-demo.sh
```

### `post-provision.yml`

This Ansible playbook is triggered by the build-demo.sh script. It:

- Connects to the Jump Host
- Runs a sequence of modular Ansible playbooks:

```yaml
- name: Post-Provisioning Automation on Jump Host
  hosts: all
  gather_facts: false

  vars:
    remote_installer_path: /var/tmp/Ansible_Automation_Platform_Setup.tar.gz
    target_dir: "{{ ansible_user_dir }}/{{ repo_url | basename | regex_replace('.git$', '') }}"

  tasks:
    - name: Configure jump host
      import_playbook: configure-jump-host.yml

    - name: Upload AAP installer
      import_playbook: upload-aap-installer.yml

    - name: Clone Git repo
      import_playbook: clone-repo-to-jump.yml
```

You can also run it manually:

```bash
ansible-playbook ansible/playbooks/post-provision.yml \
  --private-key ~/.ssh/ansible-demo-key \
  -i "<JUMP_HOST_IP>," \
  -u rheluser \
  -e "installer_path=downloads/AAP.tar.gz repo_url=https://github.com/your-org/your-repo.git"
```

### `destroy-dem.sh`

Tears down the environment in two stages:

1. **VM layer** (AAP, AD, Web Servers)
2. **Foundations layer** (NSGs, VNet, Jump Host)

Optionally cleans Terraform state files if --cleanup is passed.

```bash
./destroy-demo.sh --cleanup
```

### `reset-demo.sh`

Deletes all Terraform state and `.terraform` directories locally.
Use this when switching Azure subscriptions or force-cleaning your environment.

```bash
./reset-demo.sh
```

---

## Git & State Hygiene

✅ **Subscription-agnostic provisioning**
✅ **Reset scripts** for clean rebuilds
✅ **Secrets injected dynamically** — not stored in plaintext
✅ **Inventory separation** for provisioning vs. demo
✅ **Terraform + Ansible fully integrated**

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
| ⏳ Setup Cert Flow  | Cert issuance, renewal, and binding via playbooks        |
| ⏳ ServiceNow Hook  | Cert triggers handled via ServiceNow and Webhooks        |
| ⏳ EDA Integration  | Self-healing workflows run on alert or expiry detection  |

---

## Final Notes

- Designed for **short-lived Azure subscriptions**
- Modular, idempotent, and easily testable
- Replace `git_repo_url` in playbook variables to point to your own repo
- Use `--start-at-task` or `--tags` to target specific phases

> 💡 Fully open source and designed for re-use and extension.
