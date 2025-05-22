#!/bin/bash

##########################################
# build-demo.sh
# Dynamically builds the full demo environment:
# - Applies the foundations layer (network, NSGs)
# - Pulls outputs from foundations
# - Reads secure Windows admin password from base64 file
# - Applies the VM layer via Terraform
##########################################

set -euo pipefail

# Define directories
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDATIONS_DIR="$ROOT_DIR/terraform/foundations"
VMS_DIR="$ROOT_DIR/terraform/vms"
SECRETS_DIR="$ROOT_DIR/terraform/secrets"
ENCODED_FILE="$SECRETS_DIR/windows-admin.b64"
RANDOM_SUFFIX="dev01"
ADMIN_USERNAME="adminuser"
SSH_KEY_PATH="$HOME/.ssh/ansible-demo-key.pub"

# 🛡️ Validate required files
if [[ ! -f "$ENCODED_FILE" ]]; then
  echo "❌ Secret file not found: $ENCODED_FILE"
  exit 1
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "❌ SSH public key not found: $SSH_KEY_PATH"
  exit 1
fi

# 🔐 Decode Windows admin password
if [[ "$(uname)" == "Darwin" ]]; then
  ADMIN_PASSWORD=$(base64 -D -i "$ENCODED_FILE")
else
  ADMIN_PASSWORD=$(base64 --decode "$ENCODED_FILE")
fi

# 🧱 Step 1: Apply Foundations
echo -e "\n🏗  Applying foundations (network, NSGs)..."
terraform -chdir="$FOUNDATIONS_DIR" init
terraform -chdir="$FOUNDATIONS_DIR" apply -auto-approve \
  -var="random_suffix=$RANDOM_SUFFIX" \
  -var="admin_ssh_public_key=$(cat "$SSH_KEY_PATH")"

# 📦 Step 2: Pull outputs
SUBNET_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw subnet_id)
LINUX_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw linux_nsg_id)
WINDOWS_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw windows_nsg_id)
SSH_KEY=$(cat "$SSH_KEY_PATH")

# 🚀 Step 3: Deploy VMs
echo -e "\n🚀 Applying VM layer..."
terraform -chdir="$VMS_DIR" init
terraform -chdir="$VMS_DIR" apply -auto-approve \
  -var="location=EastAsia" \
  -var="resource_group_name=cert-renewal-demo-rg" \
  -var="subnet_id=$SUBNET_ID" \
  -var="linux_nsg_id=$LINUX_NSG_ID" \
  -var="windows_nsg_id=$WINDOWS_NSG_ID" \
  -var="admin_ssh_public_key=$SSH_KEY" \
  -var="admin_username=$ADMIN_USERNAME" \
  -var="admin_password=$ADMIN_PASSWORD" \
  -var="random_suffix=$RANDOM_SUFFIX"

echo -e "\n✅ Demo environment deployment complete."