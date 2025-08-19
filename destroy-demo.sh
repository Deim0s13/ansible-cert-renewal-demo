#!/bin/bash

##########################################
# destroy-demo.sh
# Tears down the entire demo environment:
# - Destroys VM layer
# - Destroys foundation layer  
# - Optional: cleans .terraform and state files
##########################################

set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/demo-config.env"

# ───────────────────────────────────────
# Path Definitions
# ───────────────────────────────────────
FOUNDATIONS_DIR="$SCRIPT_DIR/terraform/foundations"
VMS_DIR="$SCRIPT_DIR/terraform/vms"

# ───────────────────────────────────────
# Logging Setup
# ───────────────────────────────────────
LOG_FILE="$LOG_DIR/destroy-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG_FILE") 2>&1

log_info "Starting demo environment destruction"
log_info "Log file: $LOG_FILE"

# ───────────────────────────────────────
# Optional Cleanup Flag
# ───────────────────────────────────────
CLEANUP=false
if [[ "${1:-}" == "--cleanup" ]]; then
  CLEANUP=true
  log_info "Cleanup mode enabled - will remove Terraform state files"
fi

# ───────────────────────────────────────
# Basic Validations
# ───────────────────────────────────────
log_step "Validating prerequisites for destruction"

if [[ ! -f "$ENCODED_FILE" ]]; then
  log_warning "Secret file not found: $ENCODED_FILE"
  log_info "This might be okay if you're just cleaning up state files"
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  log_warning "SSH public key not found at $SSH_KEY_PATH"
  log_info "This might be okay if you're just cleaning up state files"
fi

# Check if we have any Terraform state to destroy
if [[ ! -f "$FOUNDATIONS_DIR/terraform.tfstate" && ! -f "$VMS_DIR/terraform.tfstate" ]]; then
  log_warning "No Terraform state files found. Environment may already be destroyed."
  if [[ "$CLEANUP" == "true" ]]; then
    log_info "Proceeding with cleanup anyway..."
  else
    log_info "Nothing to destroy. Use --cleanup flag to clean any remaining files."
    exit 0
  fi
fi

# ───────────────────────────────────────
# Decode Windows Admin Password (if available)
# ───────────────────────────────────────
if [[ -f "$ENCODED_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    ADMIN_PASSWORD=$(base64 -D -i "$ENCODED_FILE")
  else
    ADMIN_PASSWORD=$(base64 --decode "$ENCODED_FILE")
  fi
  log_info "Windows admin password decoded successfully"
else
  log_warning "Windows password file not found, using placeholder"
  ADMIN_PASSWORD="placeholder"
fi

# ───────────────────────────────────────
# Load SSH Key (if available)
# ───────────────────────────────────────
if [[ -f "$SSH_KEY_PATH" ]]; then
  SSH_KEY=$(cat "$SSH_KEY_PATH")
  log_info "SSH key loaded successfully"
else
  log_warning "SSH key not found, using placeholder"
  SSH_KEY="ssh-rsa placeholder"
fi

# ───────────────────────────────────────
# Fetch Terraform Outputs (if state exists)
# ───────────────────────────────────────
if [[ -f "$FOUNDATIONS_DIR/terraform.tfstate" ]]; then
  log_step "Fetching Terraform outputs from foundations"
  SUBNET_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw subnet_id 2>/dev/null || echo "")
  LINUX_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw linux_nsg_id 2>/dev/null || echo "")
  WINDOWS_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw windows_nsg_id 2>/dev/null || echo "")
  
  if [[ -n "$SUBNET_ID" ]]; then
    log_success "Terraform outputs retrieved successfully"
  else
    log_warning "Could not retrieve some Terraform outputs, but continuing..."
    # Set default values to allow destroy to proceed
    SUBNET_ID=""
    LINUX_NSG_ID=""
    WINDOWS_NSG_ID=""
  fi
else
  log_info "No foundation state found, skipping output retrieval"
  SUBNET_ID=""
  LINUX_NSG_ID=""
  WINDOWS_NSG_ID=""
fi

# ───────────────────────────────────────
# Destroy VM Layer
# ───────────────────────────────────────
if [[ -f "$VMS_DIR/terraform.tfstate" ]]; then
  log_step "Destroying VM layer"
  log_info "Initializing Terraform for VMs..."
  terraform -chdir="$VMS_DIR" init -upgrade -reconfigure -input=false

  log_info "Destroying virtual machines..."
  if terraform -chdir="$VMS_DIR" destroy -auto-approve \
    -var="location=$DEFAULT_LOCATION" \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -var="subnet_id=$SUBNET_ID" \
    -var="linux_nsg_id=$LINUX_NSG_ID" \
    -var="windows_nsg_id=$WINDOWS_NSG_ID" \
    -var="admin_ssh_public_key=$SSH_KEY" \
    -var="admin_username=$ADMIN_USERNAME" \
    -var="admin_password=$ADMIN_PASSWORD" \
    -var="random_suffix=$RANDOM_SUFFIX"; then
    
    log_success "VM layer destroyed successfully"
  else
    log_error "Failed to destroy VM layer"
    log_info "You may need to manually clean up resources in Azure portal"
  fi
else
  log_info "No VM state found, skipping VM destruction"
fi

# ───────────────────────────────────────
# Destroy Foundations Layer
# ───────────────────────────────────────
if [[ -f "$FOUNDATIONS_DIR/terraform.tfstate" ]]; then
  log_step "Destroying foundations layer"
  log_info "Initializing Terraform for foundations..."
  terraform -chdir="$FOUNDATIONS_DIR" init -upgrade -reconfigure -input=false

  log_info "Destroying foundation infrastructure..."
  if terraform -chdir="$FOUNDATIONS_DIR" destroy -auto-approve \
    -var="random_suffix=$RANDOM_SUFFIX" \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -var="admin_ssh_public_key=$SSH_KEY" \
    -var="location=$DEFAULT_LOCATION"; then
    
    log_success "Foundations layer destroyed successfully"
  else
    log_error "Failed to destroy foundations layer"
    log_info "You may need to manually clean up resources in Azure portal"
  fi
else
  log_info "No foundation state found, skipping foundation destruction"
fi

# ───────────────────────────────────────
# Cleanup Terraform State (Optional)
# ───────────────────────────────────────
if $CLEANUP; then
  log_step "Cleaning local Terraform state files"
  
  # Clean foundations
  if [[ -d "$FOUNDATIONS_DIR/.terraform" ]]; then
    rm -rf "$FOUNDATIONS_DIR/.terraform"
    log_info "Removed foundations .terraform directory"
  fi
  
  if ls "$FOUNDATIONS_DIR/terraform.tfstate"* >/dev/null 2>&1; then
    rm -f "$FOUNDATIONS_DIR/terraform.tfstate"*
    log_info "Removed foundations state files"
  fi
  
  # Clean VMs
  if [[ -d "$VMS_DIR/.terraform" ]]; then
    rm -rf "$VMS_DIR/.terraform"
    log_info "Removed VMs .terraform directory"
  fi
  
  if ls "$VMS_DIR/terraform.tfstate"* >/dev/null 2>&1; then
    rm -f "$VMS_DIR/terraform.tfstate"*
    log_info "Removed VMs state files"
  fi
  
  # Clean generated inventory
  if [[ -f "$SCRIPT_DIR/ansible/inventory/generated-hosts" ]]; then
    rm -f "$SCRIPT_DIR/ansible/inventory/generated-hosts"
    log_info "Removed generated inventory file"
  fi
  
  log_success "Local state files cleaned"
fi

# ───────────────────────────────────────
# Summary
# ───────────────────────────────────────
log_step "Destruction Summary"
log_success "🧹 Demo environment destruction complete!"
echo
log_info "Summary:"
echo "  📁 Log file: $LOG_FILE"
if $CLEANUP; then
  echo "  🗑️  Local state files have been cleaned"
  echo "  ✨ Environment is ready for fresh deployment"
else
  echo "  💾 Local state files preserved"
  echo "  🔄 Run with --cleanup flag to remove state files"
fi
