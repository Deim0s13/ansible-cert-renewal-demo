#!/bin/bash

##########################################
# destroy-demo.sh
# Destroys all resources in the demo environment
# - Destroys VMs first, then foundational infra
# - Optional cleanup of local Terraform state
# - Validates presence of required outputs
##########################################

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/terraform"

# Optional cleanup flag
if [[ "${1:-}" == "--cleanup" ]]; then
  echo "🧹 Cleaning local Terraform state files..."
  find "$ROOT_DIR" -type d -name ".terraform" -exec rm -rf {} +
  find "$ROOT_DIR" -name "terraform.tfstate*" -exec rm -f {} +
fi

# Function to verify that Terraform outputs exist
check_foundations_outputs() {
  echo "🔍 Checking Terraform outputs in foundations..."
  pushd "$ROOT_DIR/foundations" >/dev/null
  if ! terraform output -raw subnet_id &>/dev/null; then
    echo "❌ No outputs found in foundations. Please run 'terraform apply' in foundations first."
    exit 1
  fi
  popd >/dev/null
}

# Step 1: Check for outputs (safety guard)
check_foundations_outputs

# Step 2: Destroy VMs
echo "🔥 Destroying VM layer..."
pushd "$ROOT_DIR/vms" >/dev/null
terraform init -input=false
terraform destroy -auto-approve
popd >/dev/null

# Step 3: Destroy foundational infrastructure
echo "🧨 Destroying foundational infrastructure..."
pushd "$ROOT_DIR/foundations" >/dev/null
terraform init -input=false
terraform destroy -auto-approve
popd >/dev/null

echo -e "\n✅ Demo environment destroyed successfully."

# Optional: Suggest cleanup reminder
if [[ "${1:-}" != "--cleanup" ]]; then
  echo "ℹ️ Tip: Run './destroy-demo.sh --cleanup' to remove local Terraform files if needed."
fi
