#!/bin/bash

##########################################
# build-demo.sh
# Dynamically builds the full demo environment:
# - Pulls outputs from foundations
# - Reads secure Windows admin password from base64 file
# - Applies the VM layer via Terraform
##########################################

set -euo pipefail
cd "$(dirname "$0")/terraform/vms"

# Load Windows admin password from base64-encoded secret file
ENCODED_FILE="../secrets/windows-admin.b64"

if [[ ! -f "$ENCODED_FILE" ]]; then
  echo "❌ Secret file not found: $ENCODED_FILE"
  exit 1
fi

# Detect OS for base64 decoding
if [[ "$(uname)" == "Darwin" ]]; then
  ADMIN_PASSWORD=$(base64 -D -i "$ENCODED_FILE")
else
  ADMIN_PASSWORD=$(base64 --decode "$ENCODED_FILE")
fi

# Pull outputs from foundations
FOUNDATIONS_DIR="../foundations"
SUBNET_ID=$(cd $FOUNDATIONS_DIR && terraform output -raw subnet_id)
LINUX_NSG_ID=$(cd $FOUNDATIONS_DIR && terraform output -raw linux_nsg_id)
WINDOWS_NSG_ID=$(cd $FOUNDATIONS_DIR && terraform output -raw windows_nsg_id)
SSH_KEY=$(cat ~/.ssh/ansible-demo-key.pub)

# Terraform init and apply
terraform init

echo "\nApplying VM layer..."
terraform apply -auto-approve \
  -var="location=EastAsia" \
  -var="resource_group_name=cert-renewal-demo-rg" \
  -var="subnet_id=$SUBNET_ID" \
  -var="linux_nsg_id=$LINUX_NSG_ID" \
  -var="windows_nsg_id=$WINDOWS_NSG_ID" \
  -var="admin_ssh_public_key=$SSH_KEY" \
  -var="admin_username=adminuser" \
  -var="admin_password=$ADMIN_PASSWORD"

echo "\n✅ Demo environment deployment complete."
