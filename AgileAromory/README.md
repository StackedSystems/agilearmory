# K3s Ansible + OpenTofu Deployment

## Overview
This repository provides an automated method to deploy a hardened K3s cluster on:
- **Libvirt (KVM)**
- **VMware vCenter**
- **RHEL Satellite-managed environments**

## Repository Structure
```
k3s-ansible-opentofu/
├── ansible/  # Ansible playbooks & roles
├── opentofu/  # OpenTofu configurations
├── scripts/  # Helper scripts
├── security/  # DISA STIG compliance
├── .gitlab-ci.yml  # CI/CD automation
└── README.md
```

## Deployment
### **1. Initialize Repo**
```bash
git init
git add .
git commit -m "Initial repository setup"
git branch -M main
git remote add origin https://gitlab.com/YOUR_GITLAB_NAMESPACE/k3s-ansible-opentofu.git
git push -u origin main
```

### **2. Deploy Staging**
```bash
cd opentofu
opentofu apply -auto-approve -var="environment=dev" -var="provider=libvirt"
```

### **3. Deploy Production**
```bash
cd opentofu
opentofu apply -auto-approve -var="environment=prod" -var="provider=libvirt"
```

### **4. Deploy Ansible Configuration**
```bash
ansible-playbook -i ansible/inventories/inventory-libvirt-dev.yml ansible/playbooks/site.yml
```
