#!/usr/bin/env bash
# Writes ./ssh_config.generated using the bastion's current public IP (workbook page 8).
set -euo pipefail
cd "$(dirname "$0")/.."
IP=$(terraform -chdir=terraform output -raw bastion_public_ip)
cat > ssh_config.generated <<CFG
Host ewb-bastion
    HostName ${IP}
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

Host ewb-app-a
    HostName 10.10.2.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ProxyJump ewb-bastion

Host ewb-app-b
    HostName 10.20.1.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ProxyJump ewb-bastion
CFG
echo "Wrote ssh_config.generated (bastion ${IP}). Use: ssh -F ssh_config.generated ewb-app-a"
