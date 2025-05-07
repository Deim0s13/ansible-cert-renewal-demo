
# 🛠️ Ansible-Based Certificate Renewal Automation Demo

## ✅ Project Overview
**Purpose**  
To showcase automated, self-healing internal SSL certificate renewal using Ansible Automation Platform (AAP), Event-Driven Ansible (EDA), and ServiceNow — all built locally with a minimal VM footprint and fully reusable via Git.

**Goals**
- Demonstrate an end-to-end automated SSL certificate renewal process
- Showcase integration with Microsoft PKI, ServiceNow, and web servers
- Prove self-healing automation using Event-Driven Ansible
- Build a fully portable and reusable demo with infrastructure-as-code
- Leverage Ansible Lightspeed to support automation authoring

---

## 🧱 Architecture & Components
| Component | Role |
|----------|------|
| Ansible Automation Platform (AAP) | Executes workflows and automations |
| Event-Driven Ansible (EDA) | Triggers automation on events (e.g. cert expiry, SNOW change) |
| Git Repository | Stores all automation, EDA rules, roles, documentation |
| ServiceNow Dev Instance | Used to simulate full ITSM integration |
| Active Directory + Microsoft PKI | Certificate Authority, required for internal certs |
| Windows Web Server | Demonstrates cert renewal using IIS |
| RHEL Web Server | Demonstrates cert renewal on Linux using Apache or NGINX |
| (Optional) Network Appliance | VyOS, pfSense, or NGINX proxy to showcase certs on network gear |
| Ansible Lightspeed | AI-assisted tool to generate Ansible content efficiently |

---

## 🔁 Self-Healing Automation Workflow
| Phase | Step | Description |
|-------|------|-------------|
| Monitor | Cert expiry check | Scheduled or event-driven |
| Trigger | EDA ruleset fires | Based on cert check or SNOW ticket |
| Request | Generate CSR or use AD CS auto-enrolment |
| Approval | SNOW change request (auto/manual approval) |
| Install | Deploy cert and reload service (IIS/Apache) |
| Validate | Confirm validity and renewal success |
| Log/Notify | Log in AAP, post comment to SNOW or Teams |

---

## 🧩 Integration Points
| System | Function |
|--------|----------|
| ServiceNow | Ticketing, approvals, status updates |
| Microsoft PKI (AD CS) | Cert issuance and revocation |
| EDA | Triggers workflows on events or SNOW integration |
| Ansible Lightspeed | Assists in building playbooks, roles, automation logic |
| Logging | AAP log output, optional SNOW/Teams integration |

---

## 🖥️ Local Development Environment – Minimal Footprint
| VM | OS | Purpose | Min Specs |
|----|----|--------|-----------|
| AD & PKI Server | Windows Server 2019+ | Domain Controller + Enterprise CA | 2 vCPU / 4GB / 30GB |
| Windows Web Server | Windows Server 2019+ | IIS + cert binding | 2 vCPU / 3GB / 20GB |
| RHEL Web Server | RHEL 9 | Apache/Nginx demo site | 2 vCPU / 2GB / 15GB |
| AAP Controller | RHEL 9 | Ansible Automation Platform | 2 vCPU / 4GB / 25GB |
| EDA Server (opt) | RHEL 9 | Event-Driven Ansible | 1 vCPU / 2GB / 10GB |

---

## ⚙️ Provisioning & Automation Strategy

### Automation Tools
- **Vagrant**: Spin up local VMs
- **Ansible**: Configure VMs post-provision
- **Terraform** *(optional)*: Define infrastructure as code if switching to cloud later
- **Ansible Lightspeed**: Assist with generating playbooks and roles

### Automation Plan
1. Vagrant provisions RHEL and Windows VMs
2. Ansible configures:
   - AAP + EDA installation
   - RHEL web server setup
   - Domain join (optional)
3. Windows server configured via GUI or scripted
4. Git stores all config, provisioning, and docs

---

## 📁 Git Structure
```
cert-renewal-demo/
├── automation/
│   ├── Vagrantfile
│   ├── ansible/
│   │   ├── setup_aap.yml
│   │   ├── configure_rhel_web.yml
│   │   └── roles/
│   └── terraform/ (optional)
├── playbooks/
│   ├── check_cert_expiry.yml
│   ├── renew_cert_windows.yml
│   ├── renew_cert_rhel.yml
│   ├── validate_cert.yml
├── eda/
│   └── rulesets/
│       └── self_healing_cert_check.yml
├── docs/
│   ├── architecture-diagram.drawio
│   ├── environment-setup.md
│   ├── setup-guide.md
│   └── demo-script.md
```

---

## 📆 Recommended Timeline
| Week | Milestone | Owner |
|------|-----------|-------|
| Week 1 | Finalize architecture + VM layout | Both |
| Week 2 | Build base VMs (manually or via Vagrant) | Both |
| Week 3 | Configure AAP, AD, and PKI | You |
| Week 4 | Create renewal playbooks + roles | Colleague |
| Week 5 | Integrate EDA + ServiceNow | Both |
| Week 6 | Test, document, and publish repo | Both |

---

## 📦 Deliverables
- GitHub repository with all playbooks, EDA rules, and provisioning code
- Architecture and workflow diagrams
- Setup and run guide (`docs/`)
- Reusable demo flow with self-healing logic
- Optional: short demo video or walkthrough script
