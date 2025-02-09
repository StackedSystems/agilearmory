#!/bin/bash

set -e

REPO_NAME="AgileAromory"
echo "[INFO] Creating repository structure: $REPO_NAME"

mkdir -p $REPO_NAME/{ansible/inventories,ansible/roles/common,ansible/roles/k3s,ansible/roles/stig}
mkdir -p $REPO_NAME/{ansible/playbooks,ansible/group_vars,opentofu,scripts,security}
mkdir -p $REPO_NAME/{docs,tests,.github}

# Create inventory files
touch $REPO_NAME/ansible/inventories/inventory-libvirt-dev.yml
touch $REPO_NAME/ansible/inventories/inventory-vcenter-dev.yml
touch $REPO_NAME/ansible/inventories/inventory-libvirt-prod.yml
touch $REPO_NAME/ansible/inventories/inventory-vcenter-prod.yml

# Create main Ansible playbooks
cat <<EOF > $REPO_NAME/ansible/playbooks/site.yml
- name: Deploy K3s Cluster
  hosts: k3s_cluster
  become: true
  roles:
    - common
    - k3s
EOF

cat <<EOF > $REPO_NAME/ansible/playbooks/stig.yml
- name: Apply DISA STIG Hardening
  hosts: k3s_cluster
  become: true
  roles:
    - stig
EOF

cat <<EOF > $REPO_NAME/ansible/playbooks/upgrade.yml
- name: Upgrade K3s
  hosts: k3s_cluster
  become: true
  tasks:
    - name: Upgrade K3s binary
      shell: "curl -sfL https://get.k3s.io | sh -"
EOF

# Create OpenTofu configuration files
cat <<EOF > $REPO_NAME/opentofu/libvirt-dev.tf
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "k3s_dev" {
  count  = 3
  name   = "k3s-dev-\${count.index}"
  memory = 2048
  vcpu   = 2

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}
EOF

cat <<EOF > $REPO_NAME/opentofu/libvirt-prod.tf
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "k3s_prod" {
  count  = 3
  name   = "k3s-prod-\${count.index}"
  memory = 4096
  vcpu   = 4

  provisioner "remote-exec" {
    inline = [
      "subscription-manager register --username=your_user --password=your_pass",
      "subscription-manager attach --auto"
    ]
  }
}
EOF

cat <<EOF > $REPO_NAME/opentofu/variables.tf
variable "environment" {
  description = "Choose between dev and prod"
  type        = string
  default     = "dev"
}

variable "provider" {
  description = "Choose libvirt or vcenter"
  type        = string
  default     = "libvirt"
}
EOF

# Create security compliance STIG file
cat <<EOF > $REPO_NAME/security/disa-stig.yml
- name: Apply DISA STIG Compliance
  hosts: k3s_cluster
  become: true
  tasks:
    - name: Ensure firewalld is enabled
      ansible.builtin.systemd:
        name: firewalld
        enabled: yes
        state: started
EOF

# Create setup scripts
cat <<EOF > $REPO_NAME/scripts/setup-control-node.sh
#!/bin/bash
set -e

echo "[INFO] Installing dependencies..."
sudo apt update && sudo apt install -y ansible libvirt-clients libvirt-daemon-system qemu-kvm virt-manager opentofu git

echo "[INFO] Setting up SSH keys..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s_ansible -N ""

echo "[INFO] Cloning GitLab repository..."
git clone https://gitlab.com/YOUR_GITLAB_NAMESPACE/k3s-ansible-opentofu.git ~/k3s-ansible
EOF

chmod +x $REPO_NAME/scripts/setup-control-node.sh

# Create GitLab CI/CD pipeline
cat <<EOF > $REPO_NAME/.gitlab-ci.yml
stages:
  - validate
  - deploy

validate_infra:
  stage: validate
  script:
    - opentofu fmt -check
    - opentofu validate

deploy_libvirt:
  stage: deploy
  script:
    - opentofu apply -auto-approve -var="environment=dev" -var="provider=libvirt"
  only:
    - main
EOF

# Create README file
cat <<EOF > $REPO_NAME/README.md
# K3s Ansible + OpenTofu Deployment

## Overview
This repository provides an automated method to deploy a hardened K3s cluster on:
- **Libvirt (KVM)**
- **VMware vCenter**
- **RHEL Satellite-managed environments**

## Repository Structure
\`\`\`
k3s-ansible-opentofu/
├── ansible/  # Ansible playbooks & roles
├── opentofu/  # OpenTofu configurations
├── scripts/  # Helper scripts
├── security/  # DISA STIG compliance
├── .gitlab-ci.yml  # CI/CD automation
└── README.md
\`\`\`

## Deployment
### **1. Initialize Repo**
\`\`\`bash
git init
git add .
git commit -m "Initial repository setup"
git branch -M main
git remote add origin https://gitlab.com/YOUR_GITLAB_NAMESPACE/k3s-ansible-opentofu.git
git push -u origin main
\`\`\`

### **2. Deploy Staging**
\`\`\`bash
cd opentofu
opentofu apply -auto-approve -var="environment=dev" -var="provider=libvirt"
\`\`\`

### **3. Deploy Production**
\`\`\`bash
cd opentofu
opentofu apply -auto-approve -var="environment=prod" -var="provider=libvirt"
\`\`\`

### **4. Deploy Ansible Configuration**
\`\`\`bash
ansible-playbook -i ansible/inventories/inventory-libvirt-dev.yml ansible/playbooks/site.yml
\`\`\`
EOF

echo "[SUCCESS] Repository structure created in $REPO_NAME"
