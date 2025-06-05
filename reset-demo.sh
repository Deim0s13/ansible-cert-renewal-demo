#!/bin/bash

##########################################
# reset-demo.sh
# Cleans all local Terraform state, lock files,
# and module/plugin caches for a fresh build.
##########################################

set -euo pipefail

echo "Resetting Terraform environment..."

# Define paths
ROOT_DIR="terraform"
FOUNDATIONS_DIR="$ROOT_DIR/foundations"
VMS_DIR="$ROOT_DIR/vms"

# Function to clean a Terraform directory
clean_dir() {
  local dir="$1"
  echo "Cleaning $dir..."

  rm -rf "$dir/.terraform"
  rm -f "$dir/terraform.tfstate"
  rm -f "$dir/terraform.tfstate.backup"
  rm -f "$dir/.terraform.lock.hcl"
}

# Clean foundations and VMs
clean_dir "$FOUNDATIONS_DIR"
clean_dir "$VMS_DIR"

# Clean root if applicable
if [ -f "$ROOT_DIR/.terraform.lock.hcl" ]; then
  echo "Cleaning root lock file..."
  rm -f "$ROOT_DIR/.terraform.lock.hcl"
fi

echo "Terraform reset complete. You can now run './build-demo.sh'."
