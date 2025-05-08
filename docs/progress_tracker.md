# Project Progress Tracker: SSL Certificate Renewal Automation Demo

This document tracks the progress of building the Ansible-based certificate renewal demo.

---

## Infrastructure Setup

| Task | Status | Notes |
|------|--------|-------|
| Define VM footprint and architecture | ✅ Completed | Minimal local footprint confirmed |
| Create Vagrantfile for AD, RHEL, and Windows web servers | ⬜ Not Started | |
| Automate VM provisioning using Ansible | ⬜ Not Started | |
| Document environment setup (`environment-setup.md`) | ⬜ Not Started | |

---

## Certificate Renewal Automation

| Task | Status | Notes |
|------|--------|-------|
| `check_cert_expiry.yml` to detect expiring certs | ⬜ Not Started | |
| `renew_cert_windows.yml` to handle Windows certs | ⬜ Not Started | |
| `renew_cert_rhel.yml` to handle RHEL certs | ⬜ Not Started | |
| `validate_cert.yml` to verify deployment | ⬜ Not Started | |
| Use Ansible Lightspeed to scaffold roles | ⬜ Not Started | |

---

## Event-Driven Ansible (EDA)

| Task | Status | Notes |
|------|--------|-------|
| Create EDA ruleset for self-healing | ⬜ Not Started | |
| Integrate EDA with cert expiry detection | ⬜ Not Started | |
| Create event-driven path for SNOW integration | ⬜ Not Started | |

---

## ServiceNow Integration

| Task | Status | Notes |
|------|--------|-------|
| Trigger change requests via ServiceNow API | ⬜ Not Started | |
| Create webhook or polling rule for approval | ⬜ Not Started | |
| Post updates back to SNOW tickets | ⬜ Not Started | |

---

## Documentation & Reusability

| Task | Status | Notes |
|------|--------|-------|
| Create project `README.md` | ✅ Completed | Initial version created |
| Add diagrams (`architecture-diagram.drawio`) | ⬜ Not Started | |
| Write demo walkthrough (`demo-script.md`) | ⬜ Not Started | |
| Finalize environment + provisioning docs | ⬜ Not Started | |

---

## Total Completion Status

- Tasks Completed: 2 ✅
- Tasks In Progress / Not Started: 15 ⬜
