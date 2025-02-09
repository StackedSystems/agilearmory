#!/bin/bash
set -e

echo "[INFO] Installing dependencies..."
sudo apt update && sudo apt install -y ansible libvirt-clients libvirt-daemon-system qemu-kvm virt-manager opentofu git

echo "[INFO] Setting up SSH keys..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s_ansible -N ""

echo "[INFO] Cloning GitLab repository..."
git clone https://gitlab.com/YOUR_GITLAB_NAMESPACE/k3s-ansible-opentofu.git ~/k3s-ansible
