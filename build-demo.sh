#!/bin/bash

##########################################
# build-demo.sh
# Fully automates the provisioning of the demo:
# - Applies foundations (network, NSGs, jump host)
# - Pulls outputs from foundations
# - Decodes Windows password from base64
# - Applies VM layer via Terraform
##########################################

set -euo pipefail

# ───────────────────────────────────────
# Safety Check: Validate Azure Subscription
# ───────────────────────────────────────
EXPECTED_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "🔍 Active Azure subscription: $EXPECTED_SUBSCRIPTION_ID"

if [[ -f terraform.tfstate ]]; then
  STATE_SUBSCRIPTION_ID=$(grep -o '"subscription_id": *"[^"]*"' terraform.tfstate | head -n 1 | cut -d '"' -f4)
  if [[ "$STATE_SUBSCRIPTION_ID" != "$EXPECTED_SUBSCRIPTION_ID" ]]; then
    echo "❌ Subscription mismatch detected!"
    echo "Terraform state is tied to: $STATE_SUBSCRIPTION_ID"
    echo "Your current Azure subscription is: $EXPECTED_SUBSCRIPTION_ID"
    echo ""
    echo "🛑 Please run: ./reset-demo.sh"
    exit 1
  fi
fi

# ───────────────────────────────────────
# Paths and Configuration
# ───────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDATIONS_DIR="$ROOT_DIR/terraform/foundations"
VMS_DIR="$ROOT_DIR/terraform/vms"
SECRETS_DIR="$ROOT_DIR/terraform/secrets"

ENCODED_FILE="$SECRETS_DIR/windows-admin.b64"
SSH_KEY_PATH="$HOME/.ssh/ansible-demo-key.pub"
RANDOM_SUFFIX="dev01"
ADMIN_USERNAME="adminuser"

# ───────────────────────────────────────
# Validations
# ───────────────────────────────────────
if [[ ! -f "$ENCODED_FILE" ]]; then
  echo "❌ Secret file not found: $ENCODED_FILE"
  exit 1
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "❌ SSH public key not found: $SSH_KEY_PATH"
  exit 1
fi

# ───────────────────────────────────────
# Decode Windows Admin Password
# ───────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
  ADMIN_PASSWORD=$(base64 -D -i "$ENCODED_FILE")
else
  ADMIN_PASSWORD=$(base64 --decode "$ENCODED_FILE")
fi

# ───────────────────────────────────────
# Step 1: Apply Foundations
# ───────────────────────────────────────
echo -e "\n🏗  Applying foundations (network, NSGs)..."
terraform -chdir="$FOUNDATIONS_DIR" init
terraform -chdir="$FOUNDATIONS_DIR" apply -auto-approve \
  -var="random_suffix=$RANDOM_SUFFIX" \
  -var="admin_ssh_public_key=$(cat "$SSH_KEY_PATH")"

# ───────────────────────────────────────
# Step 2: Extract Outputs
# ───────────────────────────────────────
SUBNET_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw subnet_id)
LINUX_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw linux_nsg_id)
WINDOWS_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw windows_nsg_id)
SSH_KEY=$(cat "$SSH_KEY_PATH")

# ───────────────────────────────────────
# Step 3: Apply VM Layer
# ───────────────────────────────────────
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

  # ───────────────────────────────────────
  # Step 4: Upload AAP installer to Jump Host
  # ───────────────────────────────────────
  INSTALLER_PATH=$(find "$ROOT_DIR/downloads" -name "ansible-automation-platform-setup-bundle-*.tar.gz" | head -n 1)

  if [[ -z "$INSTALLER_PATH" ]]; then
    echo "⚠️  No AAP installer found in downloads/. Skipping upload to jump host."
  else
    echo -e "\n📡 Uploading AAP installer to Jump Host..."
    JUMP_HOST_IP=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw jump_host_ip)

    scp -o StrictHostKeyChecking=no "$INSTALLER_PATH" "rheluser@$JUMP_HOST_IP:~/"
    echo "✅ AAP installer uploaded to Jump Host: ~/$(basename "$INSTALLER_PATH")"
  fi

echo -e "\n✅ Demo environment deployment complete."
