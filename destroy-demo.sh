#!/bin/bash

##########################################
# destroy-demo.sh
# Dynamically destroys the full demo environment:
# - Reads variables from foundations output and secrets
# - Passes them to VM layer destroy
# - Then destroys foundations
##########################################

set -euo pipefail
cd "$(dirname "$0")"

# Confirm destruction
echo "⚠️  WARNING: This will permanently destroy your demo environment."
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Destroy aborted."
  exit 1
fi

# Load base64 Windows admin password
ENCODED_FILE="terraform/secrets/windows-admin.b64"
if [[ ! -f "$ENCODED_FILE" ]]; then
  echo "❌ Secret file not found: $ENCODED_FILE"
  exit 1
fi

# Decode based on OS
if [[ "$(uname)" == "Darwin" ]]; then
  ADMIN_PASSWORD=$(base64 -D -i "$ENCODED_FILE")
else
  ADMIN_PASSWORD=$(base64 --decode "$ENCODED_FILE")
fi

# Pull shared variables from foundations
FOUNDATIONS_DIR="terraform/foundations"
cd "$FOUNDATIONS_DIR"

echo "🔍 Extracting outputs from foundations..."
SUBNET_ID=$(terraform output -raw subnet_id)
LINUX_NSG_ID=$(terraform output -raw linux_nsg_id)
WINDOWS_NSG_ID=$(terraform output -raw windows_nsg_id)

cd ../..

# Define other vars
RANDOM_SUFFIX="dev01"
SSH_KEY=$(cat ~/.ssh/ansible-demo-key.pub)
LOCATION="EastAsia"
RESOURCE_GROUP_NAME="cert-renewal-demo-rg"
ADMIN_USERNAME="adminuser"

# Destroy VM layer
echo "🔻 Destroying VM layer..."
cd terraform/vms
terraform destroy -auto-approve \
  -var="location=$LOCATION" \
  -var="resource_group_name=$RESOURCE_GROUP_NAME" \
  -var="subnet_id=$SUBNET_ID" \
  -var="linux_nsg_id=$LINUX_NSG_ID" \
  -var="windows_nsg_id=$WINDOWS_NSG_ID" \
  -var="admin_ssh_public_key=$SSH_KEY" \
  -var="admin_username=$ADMIN_USERNAME" \
  -var="admin_password=$ADMIN_PASSWORD" \
  -var="random_suffix=$RANDOM_SUFFIX"

# Destroy foundations last
echo "🔻 Destroying foundational resources..."
cd ../foundations
terraform destroy -auto-approve \
  -var="random_suffix=$RANDOM_SUFFIX" \
  -var="admin_ssh_public_key=$SSH_KEY"

echo "✅ Demo environment destroyed successfully."