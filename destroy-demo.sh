#!/bin/bash

##########################################
# destroy-demo.sh
# Tears down the entire demo environment:
# - Destroys VM layer
# - Destroys foundation layer
# - Optional: cleans .terraform and state files
##########################################

set -euo pipefail

# ───────────────────────────────────────
# Optional Cleanup Flag
# ───────────────────────────────────────
CLEANUP=false
if [[ "${1:-}" == "--cleanup" ]]; then
  CLEANUP=true
fi

# ───────────────────────────────────────
# Path Definitions
# ───────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDATIONS_DIR="$ROOT_DIR/terraform/foundations"
VMS_DIR="$ROOT_DIR/terraform/vms"
SECRETS_FILE="$ROOT_DIR/terraform/secrets/windows-admin.b64"
SSH_KEY_FILE="$HOME/.ssh/ansible-demo-key.pub"
RANDOM_SUFFIX="dev01"
ADMIN_USERNAME="adminuser"

# ───────────────────────────────────────
# Validations
# ───────────────────────────────────────
if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "❌ Secret file not found: $SECRETS_FILE"
  exit 1
fi

if [[ ! -f "$SSH_KEY_FILE" ]]; then
  echo "❌ SSH public key not found at $SSH_KEY_FILE"
  exit 1
fi

# ───────────────────────────────────────
# Decode Windows Admin Password
# ───────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
  ADMIN_PASSWORD=$(base64 -D -i "$SECRETS_FILE")
else
  ADMIN_PASSWORD=$(base64 --decode "$SECRETS_FILE")
fi

# ───────────────────────────────────────
# Load SSH Key
# ───────────────────────────────────────
SSH_KEY=$(cat "$SSH_KEY_FILE")

# ───────────────────────────────────────
# Destroy VM Layer
# ───────────────────────────────────────
echo "Destroying VM layer..."
terraform -chdir="$VMS_DIR" init -upgrade -reconfigure -input=false

terraform -chdir="$VMS_DIR" destroy -auto-approve \
  -var="location=EastAsia" \
  -var="resource_group_name=cert-renewal-demo-rg" \
  -var="subnet_id=$(terraform -chdir=$FOUNDATIONS_DIR output -raw subnet_id)" \
  -var="linux_nsg_id=$(terraform -chdir=$FOUNDATIONS_DIR output -raw linux_nsg_id)" \
  -var="windows_nsg_id=$(terraform -chdir=$FOUNDATIONS_DIR output -raw windows_nsg_id)" \
  -var="admin_ssh_public_key=$SSH_KEY" \
  -var="admin_username=$ADMIN_USERNAME" \
  -var="admin_password=$ADMIN_PASSWORD" \
  -var="random_suffix=$RANDOM_SUFFIX"

# ───────────────────────────────────────
# Destroy Foundations Layer
# ───────────────────────────────────────
echo "Destroying foundation layer..."
terraform -chdir="$FOUNDATIONS_DIR" init -upgrade -reconfigure -input=false

terraform -chdir="$FOUNDATIONS_DIR" destroy -auto-approve \
  -var="random_suffix=$RANDOM_SUFFIX" \
  -var="admin_ssh_public_key=$SSH_KEY"

# ───────────────────────────────────────
# Cleanup Terraform State (Optional)
# ───────────────────────────────────────
if $CLEANUP; then
  echo "Cleaning local Terraform state files..."
  rm -rf "$FOUNDATIONS_DIR/.terraform" "$FOUNDATIONS_DIR/terraform.tfstate"*
  rm -rf "$VMS_DIR/.terraform" "$VMS_DIR/terraform.tfstate"*
fi

echo "Demo environment destroyed successfully."
