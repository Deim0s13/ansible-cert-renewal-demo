#!/bin/bash

##########################################
# build-demo.sh
# Fully automates the provisioning of the demo:
# - Validates environment prerequisites
# - Applies foundations (network, NSGs, jump host)
# - Pulls outputs from foundations
# - Decodes Windows password from base64
# - Applies VM layer via Terraform
# - Runs post-provisioning Ansible from local to jump host
##########################################

set -euo pipefail

# Source shared configuration and validation functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/demo-config.env"
source "$SCRIPT_DIR/demo-validation.sh"

# ───────────────────────────────────────
# Logging Setup  
# ───────────────────────────────────────
LOG_FILE="$LOG_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG_FILE") 2>&1

log_info "Starting demo environment deployment"
log_info "Log file: $LOG_FILE"

# ───────────────────────────────────────
# Pre-flight Validation
# ───────────────────────────────────────
log_step "Running pre-flight validations"
if ! validate_all; then
    log_error "Pre-flight validation failed. Aborting deployment."
    exit 1
fi

# ───────────────────────────────────────
# Auto-Reset and Cleanup Functions
# ───────────────────────────────────────
auto_reset_terraform_state() {
    log_step "Checking for Terraform state issues"
    
    local foundations_state="terraform/foundations/terraform.tfstate"
    local vms_state="terraform/vms/terraform.tfstate"
    local needs_reset=false
    
    # Check subscription consistency
    if [[ -f "$foundations_state" ]]; then
        local state_subscription=$(grep -o '"subscription_id": *"[^"]*"' "$foundations_state" | head -n 1 | cut -d '"' -f4 2>/dev/null || echo "")
        local current_subscription=$(az account show --query id -o tsv 2>/dev/null || echo "")
        
        if [[ -n "$state_subscription" && -n "$current_subscription" && "$state_subscription" != "$current_subscription" ]]; then
            log_warning "Terraform state subscription mismatch detected"
            log_info "State subscription: $state_subscription"
            log_info "Current subscription: $current_subscription"
            needs_reset=true
        fi
    fi
    
    if [[ "$needs_reset" == "true" ]]; then
        log_warning "Auto-resetting Terraform state for clean deployment"
        
        # Clean foundations
        if [[ -d "terraform/foundations/.terraform" ]]; then
            rm -rf "terraform/foundations/.terraform"
            log_info "Removed foundations .terraform directory"
        fi
        
        if ls terraform/foundations/terraform.tfstate* >/dev/null 2>&1; then
            rm -f terraform/foundations/terraform.tfstate*
            log_info "Removed foundations state files"
        fi
        
        # Clean VMs
        if [[ -d "terraform/vms/.terraform" ]]; then
            rm -rf "terraform/vms/.terraform"
            log_info "Removed VMs .terraform directory"
        fi
        
        if ls terraform/vms/terraform.tfstate* >/dev/null 2>&1; then
            rm -f terraform/vms/terraform.tfstate*
            log_info "Removed VMs state files"
        fi
        
        # Clean generated inventory
        if [[ -f "ansible/inventory/generated-hosts" ]]; then
            rm -f "ansible/inventory/generated-hosts"
            log_info "Removed generated inventory file"
        fi
        
        log_success "Terraform state reset complete"
    else
        log_info "Terraform state is clean"
    fi
}

auto_cleanup_azure_resources() {
    log_step "Checking for conflicting Azure resources"
    
    local target_rg="$RESOURCE_GROUP_NAME"
    
    # Check if target resource group exists
    if az group show --name "$target_rg" &>/dev/null; then
        log_warning "Resource group '$target_rg' already exists"
        
        # Check if it has resources
        local resource_count=$(az resource list --resource-group "$target_rg" --query "length(@)" -o tsv 2>/dev/null || echo "0")
        
        if [[ "$resource_count" -gt 0 ]]; then
            log_warning "Resource group contains $resource_count resources that could conflict"
            log_info "Auto-cleaning existing resources for fresh deployment"
            
            # Show what will be cleaned
            log_info "Resources being cleaned:"
            az resource list --resource-group "$target_rg" --query "[].{Name:name, Type:type}" -o table
            
            # Delete the resource group
            log_info "Deleting resource group '$target_rg'..."
            az group delete --name "$target_rg" --yes --no-wait
            
            # Wait a moment for deletion to start
            log_info "Waiting for deletion to initiate..."
            sleep 10
            
            # Wait for deletion to complete
            log_info "Waiting for resource group deletion to complete..."
            local wait_count=0
            while az group show --name "$target_rg" &>/dev/null && [[ $wait_count -lt 30 ]]; do
                echo -n "."
                sleep 10
                ((wait_count++))
            done
            echo
            
            if az group show --name "$target_rg" &>/dev/null; then
                log_warning "Resource group deletion still in progress (continuing anyway)"
            else
                log_success "Resource group '$target_rg' successfully deleted"
            fi
        else
            log_info "Resource group '$target_rg' exists but is empty"
        fi
    else
        log_info "No conflicting Azure resources found"
    fi
}

# ───────────────────────────────────────
# Auto-Reset and Cleanup Execution
# ───────────────────────────────────────
auto_reset_terraform_state
auto_cleanup_azure_resources

# ───────────────────────────────────────
# Setup paths from config
# ───────────────────────────────────────
FOUNDATIONS_DIR="$SCRIPT_DIR/terraform/foundations"
VMS_DIR="$SCRIPT_DIR/terraform/vms"
export PRIVATE_KEY_PATH # Export for ansible-playbook

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
log_step "Applying foundations (network, NSGs)"
log_info "Initializing Terraform for foundations..."
terraform -chdir="$FOUNDATIONS_DIR" init

log_info "Deploying foundation infrastructure..."
terraform -chdir="$FOUNDATIONS_DIR" apply -auto-approve \
  -var="random_suffix=$RANDOM_SUFFIX" \
  -var="resource_group_name=$RESOURCE_GROUP_NAME" \
  -var="admin_ssh_public_key=$(cat "$SSH_KEY_PATH")" \
  -var="location=$DEFAULT_LOCATION"

log_success "Foundation infrastructure deployed successfully"

# ───────────────────────────────────────
# Step 2: Extract Outputs
# ───────────────────────────────────────
log_step "Extracting Terraform output values"
SUBNET_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw subnet_id)
LINUX_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw linux_nsg_id)
WINDOWS_NSG_ID=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw windows_nsg_id)
JUMP_HOST_IP=$(terraform -chdir="$FOUNDATIONS_DIR" output -raw jump_host_ip)
SSH_KEY=$(cat "$SSH_KEY_PATH")

log_info "Jump Host IP: $JUMP_HOST_IP"
log_info "Subnet ID: $SUBNET_ID"
log_success "Infrastructure outputs extracted successfully"

# ───────────────────────────────────────
# Step 2b: Create Dynamic Inventory for Ansible (Initial - for connecting to jump host)
# ───────────────────────────────────────
INVENTORY_FILE="$SCRIPT_DIR/ansible/inventory/generated-hosts"

echo -e "\n Generating dynamic inventory at $INVENTORY_FILE..."
cat > "$INVENTORY_FILE" <<EOF
[jump]
jump-host ansible_host=$JUMP_HOST_IP ansible_user=rheluser ansible_ssh_private_key_file=$PRIVATE_KEY_PATH ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# ───────────────────────────────────────
# Step 3: Apply VM Layer
# ───────────────────────────────────────
log_step "Deploying VM layer (AAP, Web servers, AD/PKI)"
log_info "Initializing Terraform for VMs..."
terraform -chdir="$VMS_DIR" init

log_info "Deploying virtual machines..."
terraform -chdir="$VMS_DIR" apply -auto-approve \
  -var="location=$DEFAULT_LOCATION" \
  -var="resource_group_name=$RESOURCE_GROUP_NAME" \
  -var="subnet_id=$SUBNET_ID" \
  -var="linux_nsg_id=$LINUX_NSG_ID" \
  -var="windows_nsg_id=$WINDOWS_NSG_ID" \
  -var="admin_ssh_public_key=$SSH_KEY" \
  -var="admin_username=$ADMIN_USERNAME" \
  -var="admin_password=$ADMIN_PASSWORD" \
  -var="random_suffix=$RANDOM_SUFFIX"

log_success "Virtual machines deployed successfully"

# ───────────────────────────────────────
# Step 4: Generate Full Inventory for Post-Provisioning (CRITICAL CHANGE HERE)
# ───────────────────────────────────────
echo -e "\n Generating dynamic inventory at $INVENTORY_FILE (full)..."
cat > "$INVENTORY_FILE" <<EOF

[jump]
jump-host ansible_host=${JUMP_HOST_IP} ansible_user=rheluser ansible_ssh_private_key_file=${PRIVATE_KEY_PATH} ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

[aap]
aap-host ansible_host=10.0.1.12 ansible_user=rheluser ansible_ssh_private_key_file=/home/rheluser/.ssh/ansible-demo-key

[rhel_web]
rhel-web ansible_host=10.0.1.11 ansible_user=rheluser ansible_ssh_private_key_file=/home/rheluser/.ssh/ansible-demo-key

[ad_pki]
ad-pki ansible_host=10.0.1.14 ansible_user=${ADMIN_USERNAME} ansible_password=${ADMIN_PASSWORD} ansible_connection=winrm ansible_winrm_transport=basic

[win_web]
win-web ansible_host=10.0.1.13 ansible_user=${ADMIN_USERNAME} ansible_password=${ADMIN_PASSWORD} ansible_connection=winrm ansible_winrm_transport=basic

[web_servers:children]
rhel_web
win_web

[linux:children]
jump
aap
rhel_web

[windows:children]
ad_pki
win_web
EOF

# ───────────────────────────────────────
# Step 5: Run Ansible Post-Provisioning Playbook
# ───────────────────────────────────────
log_step "Running Ansible post-provisioning automation"

POST_PROVISION_INVENTORY="$INVENTORY_FILE"
POST_PROVISION_CONFIG="$SCRIPT_DIR/ansible/ansible.cfg"

log_info "Starting Ansible playbook execution..."
log_info "This will configure the jump host, upload AAP installer, and bootstrap SSH connectivity"

if ANSIBLE_CONFIG="$POST_PROVISION_CONFIG" \
ansible-playbook ansible/playbooks/post-provisioning.yml \
  -i "$POST_PROVISION_INVENTORY" \
  -e "installer_path=$INSTALLER_PATH repo_url=$GIT_REPO_URL private_key_path=$PRIVATE_KEY_PATH"; then
  
  log_success "Post-provisioning completed successfully"
else
  log_error "Post-provisioning failed. Check Ansible logs above."
  log_info "You can retry with: ansible-playbook ansible/playbooks/post-provisioning.yml -i $POST_PROVISION_INVENTORY"
  exit 1
fi

# ───────────────────────────────────────
# Deployment Summary
# ───────────────────────────────────────
log_step "Deployment Summary"
log_success "🎉 Demo environment is ready!"
echo
log_info "Connection Details:"
echo "  📡 Jump Host: ssh rheluser@$JUMP_HOST_IP"
echo "  🌐 AAP Controller: http://$AAP_HOST_IP (after AAP installation completes)"
echo "  📁 Log file: $LOG_FILE"
echo
log_info "Next Steps:"
echo "  1. SSH to jump host: ssh rheluser@$JUMP_HOST_IP"
echo "  2. Navigate to project: cd ansible-cert-renewal-demo"
echo "  3. Check AAP installation: sudo tail -f /opt/ansible-automation-platform-setup*/setup.log"
echo
log_warning "Remember to run './destroy-demo.sh --cleanup' when done to clean up resources!"
