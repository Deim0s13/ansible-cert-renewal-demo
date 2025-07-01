# Ansible‑Based Certificate Renewal Automation Demo

## Project Overview

### Purpose

This repo demonstrates a **fully automated, self‑healing certificate‑renewal workflow** built with:

* **Ansible Automation Platform (AAP)** ‑ installs automatically during the build
* **Event‑Driven Ansible (EDA)** for reactive remediation
* **Microsoft PKI (AD CS)** providing the enterprise CA
* **ServiceNow** for IT‑service approvals & notifications

The lab is provisioned on **Azure** with a *hybrid* toolset:

* **Terraform + Bash** → builds the cloud infrastructure
* **Ansible**  → finishes configuration, installs AAP, sets up the PKI pipeline

---

## Target Architecture

| Component              | Purpose / Notes                                   |
| ---------------------- | ------------------------------------------------- |
| **Jump Host (RHEL)**   | Primary Ansible control node & AAP installer host |
| **AAP Node**           | Runs Ansible Automation Platform (single‑node)    |
| **Windows AD + PKI**   | Domain Controller & Certificate Authority         |
| **Windows Web Server** | IIS demo site ‑ consumes auto‑renewed certs       |
| **RHEL Web Server**    | Apache/Nginx demo site for Linux cert flow        |
| **ServiceNow**         | ITSM approvals / change management                |
| **EDA Controller**     | Executes remediation policies on expiry / alerts  |

---

## Provisioning Workflow

### 1  `build-demo.sh`

1. Validates Azure subscription & SSH prerequisites
2. Applies **foundations** Terraform (VNet, NSGs, Jump Host)
3. Applies **VM layer** Terraform (AAP, AD/PKI, Web servers)
4. Copies the disconnected‑bundle **once** to the Jump Host
5. Fires **Ansible post‑provisioning** on the Jump Host

### 2  Post‑Provisioning (Ansible)

The `post-provision.yml` playbook (triggered from `build-demo.sh`) now performs **four** modular steps:

| Order | Import Playbook            | Purpose                                     |
| ----: | -------------------------- | ------------------------------------------- |
|     0 | `copy-private-key.yml`     | injects control‑node SSH key onto Jump Host |
|     1 | `configure-jump-host.yml`  | installs Python, Podman, etc.               |
|     2 | `upload-aap-installer.yml` | copies `aap‑setup‑*.tar.gz` to `/var/tmp`   |
|     3 | `install-aap.yml`          | **runs AAP installer from the Jump Host**   |
|     4 | `resize-disks-aap.yml`     | expands & mounts `/opt` LVM on the AAP node |

> 🔄 **No second hop!**  The bundle is **not** copied again—`install‑aap` uses `rsync` over SSH to stream the bundle directly from the Jump Host to the AAP node before running `setup.sh`.

---

## Repository Layout (trimmed)

```text
ansible-cert-renewal-demo/
├── terraform/                   # networking & VM modules
├── downloads/                   # AAP bundle (ignored by git)
├── ansible/
│   ├── inventory/
│   │   └── demo-hosts           # static inventory for jump & aap
│   ├── playbooks/
│   │   ├── post-provision.yml
│   │   ├── upload-aap-installer.yml
│   │   ├── install-aap.yml
│   │   └── …
│   ├── roles/
│   │   └── aap_install/         # rsync & installer logic
│   └── ansible.cfg
├── build-demo.sh                # one‑command deploy
└── destroy-demo.sh              # full teardown
```

---

## Key Playbooks & Roles

### `upload-aap-installer.yml`

* Copies the disconnected bundle from **your laptop → Jump Host** with `rsync`.
* Skips upload if the checksum on the Jump Host matches.

### `install-aap.yml`

Runs only on the **Jump Host** and includes the `aap_install` role.

Role highlights:

1. Validates vault secrets (`aap_admin_password`, `aap_pg_password`).
2. Installs `python3`, `podman`, `tar`, `unzip` on AAP node (via yum module).
3. `rsync`‑pushes the tarball **directly** to the AAP node.
4. Unpacks bundle under `/opt` and auto‑discovers the versioned directory.
5. Generates a single‑node inventory.
6. Executes `setup.sh`; tail of log is printed for visibility.

Run manually if needed:

```bash
ansible-playbook ansible/playbooks/install-aap.yml \
  -i ansible/inventory/demo-hosts               \
  --limit jump                                  \
  --vault-id @prompt
```

---

## Automation Phase Tracker

| Phase                  | Status | Notes                       |
| ---------------------- | ------ | --------------------------- |
| Provision infra (TF)   | ✅ Done | VNet + all VMs              |
| Upload AAP bundle      | ✅ Done | Single hop to Jump Host     |
| Install AAP            | ✅ Done | From Jump Host → AAP node   |
| Configure PKI          | ⏳ Next | AD CS playbooks (coming)    |
| Cert renewal workflows | ⏳ Next | IIS / Apache bindings       |
| ServiceNow integration | ⏳ Next | Webhooks & approvals        |
| EDA self‑healing       | ⏳ Next | Fires on cert‑expiry events |

---

## Quick Commands

```bash
# Kick off EVERYTHING (Terraform + Ansible)
./build-demo.sh

# Tear it all down
./destroy-demo.sh --cleanup

# Re‑run only post‑provision on an existing lab
ansible-playbook ansible/playbooks/post-provision.yml \
  -i ansible/inventory/demo-hosts --limit jump
```

---

## Good‑to‑Know

* **Subscription‑agnostic** – Azure IDs are param‑driven & cleaned with `reset-demo.sh`.
* **Secrets** stay in `ansible-vault`; never committed unencrypted.
* **Idempotent** – Safe to re‑run any playbook; changed‑when guards prevent churn.
* **Extensible** – Swap the CA or ITSM integrations by editing group vars & roles only.

> 💡 PRs welcome! Feel free to fork and adapt to your own demo needs.
