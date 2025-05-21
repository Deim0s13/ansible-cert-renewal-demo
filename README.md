
# Ansible-Based Certificate Renewal Automation Demo

## Project Overview

### Purpose

To showcase automated, self-healing internal SSL certificate renewal using Ansible Automation Platform (AAP), Event-Driven Ansible (EDA), and ServiceNow — deployable both **locally** and in **Azure**, and fully reusable via Git.

### Goals

- Demonstrate an end-to-end automated SSL certificate renewal process
- Showcase integration with Microsoft PKI, ServiceNow, and web servers
- Prove self-healing automation using Event-Driven Ansible
- Build a fully automated and redeployable lab using infrastructure-as-code
- Leverage Ansible Lightspeed to accelerate and assist automation authoring

---

## Architecture & Components

| Component | Role |
|----------|------|
| Ansible Automation Platform (AAP) | Executes workflows and automations |
| Event-Driven Ansible (EDA) | Triggers automation on events (e.g. cert expiry, SNOW change) |
| Git Repository | Stores all automation, EDA rules, roles, documentation |
| ServiceNow Dev Instance | Simulates full ITSM lifecycle integration |
| Active Directory + Microsoft PKI | Certificate Authority for issuing/renewing internal certs |
| Windows Web Server | Demonstrates SSL renewal using IIS |
| RHEL Web Server | Demonstrates SSL renewal using Apache or NGINX |
| (Optional) Network Appliance | VyOS, pfSense, or NGINX reverse proxy (future) |
| Ansible Lightspeed | AI-assisted generation of Ansible content |

---

## Self-Healing Automation Workflow

| Phase | Step | Description |
|-------|------|-------------|
| Monitor | Check for expiring certs | Scheduled or event-driven check |
| Trigger | EDA rule initiates flow | Via expiry alert or ServiceNow webhook |
| Request | Generate CSR or auto-request | Against AD CS or external CA |
| Approval | SNOW Change Request | Auto/manual depending on rules |
| Install | Deploy and bind certificate | Web server restart/reload included |
| Validate | Verify deployment success | Check expiry, hostname, and chain |
| Log/Notify | Log and alert | Post to AAP logs, ServiceNow, or Teams |

---

## Integration Points

| System | Function |
|--------|----------|
| ServiceNow | Change requests, approvals, ticketing |
| Microsoft PKI (AD CS) | Cert issuance and revocation |
| EDA | Triggers automation workflows |
| Ansible Lightspeed | Assists with playbook and role creation |
| Logging/Alerting | AAP, SNOW comments, or Teams webhook |

---

## Deployment Options

| Environment | Method | Notes |
|-------------|--------|-------|
| **Azure** | Terraform + Ansible | Full automation of networking + VMs |
| **Local (VMware)** | Vagrant + Ansible | Alienware M18 with VMware Workstation |
| *(Optional)* | Podman or cloud-native containers | For lightweight AAP/EDA or future containerized version |

---

## Provisioning & Automation Strategy

### Tools Used

- **Terraform**: Provisioning in Azure (VMs, networking, IPs)
- **Vagrant + VMware**: Local VM provisioning
- **Ansible**: VM configuration, role execution, cert handling
- **Ansible Lightspeed**: Assisted authoring of roles/playbooks
- **Git**: Source of truth

### Automation Flow

1. Provision infrastructure (Azure via Terraform, or local via Vagrant)
2. Run Ansible to configure AAP, web servers, PKI, etc.
3. EDA listens for cert events or SNOW integration
4. Renewal logic executes and validates automatically

---

## Git Structure

```text
ansible-cert-renewal-demo/
├── terraform/                  # Azure IAC
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── automation/
│   ├── Vagrantfile             # Local lab option
│   └── network/
│       └── cert-net.xml        # Libvirt fallback (if needed)
├── ansible/
│   ├── setup_aap.yml
│   ├── configure_rhel_web.yml
│   └── roles/
├── playbooks/
│   ├── check_cert_expiry.yml
│   ├── renew_cert_windows.yml
│   ├── renew_cert_rhel.yml
│   └── validate_cert.yml
├── eda/
│   └── rulesets/
│       └── self_healing_cert_check.yml
├── docs/
│   ├── architecture-diagram.drawio
│   ├── environment-setup.md
│   ├── azure-deployment.md
│   └── demo-script.md
```

---

## Deployment Timeline (TBC)

| Stage | Milestone | Owner |
|-------|-----------|-------|
| 1 | Finalize cross-platform architecture | Both |
| 2 | Create Terraform + Ansible provisioning | Both |
| 3 | Build local and Azure lab environments | You |
| 4 | Create renewal automation and EDA rules | Colleague |
| 5 | Integrate with ServiceNow | Both |
| 6 | Test, document, and publish | Both |

---

## Deliverables

- GitHub repo with provisioning, automation, and documentation
- Self-healing, event-driven certificate renewal demo
- Azure deployment template and Vagrant fallback
- Architecture diagrams and setup walkthrough
- Optional: recorded or live demo walkthrough
