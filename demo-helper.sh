#!/bin/bash
# ===================================================================
# Demo Helper Script
# Provides useful shortcuts and troubleshooting commands
# ===================================================================

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/demo-config.env"
source "$SCRIPT_DIR/demo-validation.sh"

show_help() {
    cat << 'EOF'
🚀 Demo Environment Helper

USAGE:
  ./demo-helper.sh COMMAND

COMMANDS:
  check           Run comprehensive environment validation
  status          Show current deployment status
  connect         Get SSH connection command for jump host
  aap-status      Check AAP installation progress
  aap-logs        Show AAP installation logs
  inventory       Display current inventory file
  terraform-plan  Plan terraform changes without applying
  clean-logs      Remove old log files
  ssh-keygen      Generate SSH keys for demo
  password-gen    Generate and encode Windows password
  help            Show this help message

EXAMPLES:
  ./demo-helper.sh check          # Validate environment
  ./demo-helper.sh status         # Check deployment status
  ./demo-helper.sh connect        # Get SSH command
  ./demo-helper.sh aap-logs       # Monitor AAP installation

EOF
}

check_command() {
    log_step "Running comprehensive validation"
    validate_all
}

status_command() {
    log_step "Demo Environment Status"
    
    # Check Terraform state
    local foundations_state="terraform/foundations/terraform.tfstate"
    local vms_state="terraform/vms/terraform.tfstate"
    
    if [[ -f "$foundations_state" ]]; then
        log_success "Foundations: Deployed"
        local jump_ip=$(terraform -chdir="terraform/foundations" output -raw jump_host_ip 2>/dev/null || echo "Unknown")
        log_info "Jump Host IP: $jump_ip"
    else
        log_warning "Foundations: Not deployed"
    fi
    
    if [[ -f "$vms_state" ]]; then
        log_success "VMs: Deployed"
    else
        log_warning "VMs: Not deployed"
    fi
    
    # Check if jump host is accessible (if deployed)
    if [[ -f "$foundations_state" ]]; then
        local jump_ip=$(terraform -chdir="terraform/foundations" output -raw jump_host_ip 2>/dev/null)
        if [[ -n "$jump_ip" ]]; then
            log_info "Testing jump host connectivity..."
            if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" rheluser@"$jump_ip" "echo 'Connected successfully'" 2>/dev/null; then
                log_success "Jump host: Accessible"
            else
                log_warning "Jump host: Not accessible (may still be booting)"
            fi
        fi
    fi
}

connect_command() {
    local foundations_state="terraform/foundations/terraform.tfstate"
    
    if [[ ! -f "$foundations_state" ]]; then
        log_error "Environment not deployed. Run ./build-demo.sh first"
        return 1
    fi
    
    local jump_ip=$(terraform -chdir="terraform/foundations" output -raw jump_host_ip 2>/dev/null)
    if [[ -z "$jump_ip" ]]; then
        log_error "Could not get jump host IP"
        return 1
    fi
    
    log_info "SSH Connection Command:"
    echo
    echo "  ssh -i $PRIVATE_KEY_PATH rheluser@$jump_ip"
    echo
    log_info "Or copy and run this command:"
    echo "ssh -i $PRIVATE_KEY_PATH rheluser@$jump_ip"
}

aap_status_command() {
    log_step "Checking AAP installation status"
    
    local jump_ip=$(terraform -chdir="terraform/foundations" output -raw jump_host_ip 2>/dev/null)
    if [[ -z "$jump_ip" ]]; then
        log_error "Environment not deployed or jump host IP not available"
        return 1
    fi
    
    log_info "Connecting to jump host to check AAP status..."
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" rheluser@"$jump_ip" << 'REMOTE_SCRIPT'
        echo "🔍 Checking AAP installation status..."
        
        # Check if installation directory exists
        if [[ -d /opt/ansible-automation-platform-setup* ]]; then
            setup_dir=$(ls -d /opt/ansible-automation-platform-setup* | head -n1)
            echo "✅ AAP setup directory found: $setup_dir"
            
            # Check if installation is running
            if pgrep -f setup.sh > /dev/null; then
                echo "🔄 AAP installation is currently running"
                echo "📊 Installation progress (last 10 lines):"
                tail -n 10 "$setup_dir/setup.log" 2>/dev/null || echo "No setup.log found yet"
            elif [[ -f "$setup_dir/setup.log" ]]; then
                echo "📋 Installation appears complete. Log tail:"
                tail -n 10 "$setup_dir/setup.log"
                
                # Check if AAP is running
                if systemctl is-active --quiet automation-controller-web; then
                    echo "✅ AAP Controller is running"
                    echo "🌐 Access at: http://10.0.1.12"
                else
                    echo "⚠️  AAP Controller is not running yet"
                fi
            else
                echo "⚠️  No setup.log found - installation may not have started"
            fi
        else
            echo "❌ AAP setup directory not found"
        fi
REMOTE_SCRIPT
}

aap_logs_command() {
    local jump_ip=$(terraform -chdir="terraform/foundations" output -raw jump_host_ip 2>/dev/null)
    if [[ -z "$jump_ip" ]]; then
        log_error "Environment not deployed or jump host IP not available"
        return 1
    fi
    
    log_info "Streaming AAP installation logs..."
    log_info "Press Ctrl+C to stop"
    
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" rheluser@"$jump_ip" \
        "sudo tail -f /opt/ansible-automation-platform-setup*/setup.log 2>/dev/null || echo 'Setup log not found yet. Installation may not have started.'"
}

inventory_command() {
    local inventory_file="ansible/inventory/generated-hosts"
    
    if [[ -f "$inventory_file" ]]; then
        log_info "Current inventory file ($inventory_file):"
        echo
        cat "$inventory_file"
    else
        log_warning "No generated inventory file found"
        log_info "Static inventory (ansible/inventory/demo-hosts):"
        if [[ -f "ansible/inventory/demo-hosts" ]]; then
            echo
            cat "ansible/inventory/demo-hosts"
        else
            log_error "No inventory files found"
        fi
    fi
}

terraform_plan_command() {
    log_step "Running Terraform plan for both layers"
    
    if [[ ! -f "$ENCODED_FILE" ]]; then
        log_error "Secrets file required for planning. Create: $ENCODED_FILE"
        return 1
    fi
    
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_error "SSH key required for planning: $SSH_KEY_PATH"
        return 1
    fi
    
    # Plan foundations
    log_info "Planning foundations..."
    terraform -chdir="terraform/foundations" init -input=false
    terraform -chdir="terraform/foundations" plan \
        -var="random_suffix=$RANDOM_SUFFIX" \
        -var="admin_ssh_public_key=$(cat "$SSH_KEY_PATH")" \
        -var="location=$DEFAULT_LOCATION"
    
    # Plan VMs if foundations exist
    if [[ -f "terraform/foundations/terraform.tfstate" ]]; then
        log_info "Planning VMs..."
        local subnet_id=$(terraform -chdir="terraform/foundations" output -raw subnet_id 2>/dev/null)
        local linux_nsg_id=$(terraform -chdir="terraform/foundations" output -raw linux_nsg_id 2>/dev/null)
        local windows_nsg_id=$(terraform -chdir="terraform/foundations" output -raw windows_nsg_id 2>/dev/null)
        
        if [[ -n "$subnet_id" ]]; then
            local admin_password
            if [[ "$(uname)" == "Darwin" ]]; then
                admin_password=$(base64 -D -i "$ENCODED_FILE")
            else
                admin_password=$(base64 --decode "$ENCODED_FILE")
            fi
            
            terraform -chdir="terraform/vms" init -input=false
            terraform -chdir="terraform/vms" plan \
                -var="location=$DEFAULT_LOCATION" \
                -var="resource_group_name=$RESOURCE_GROUP_NAME" \
                -var="subnet_id=$subnet_id" \
                -var="linux_nsg_id=$linux_nsg_id" \
                -var="windows_nsg_id=$windows_nsg_id" \
                -var="admin_ssh_public_key=$(cat "$SSH_KEY_PATH")" \
                -var="admin_username=$ADMIN_USERNAME" \
                -var="admin_password=$admin_password" \
                -var="random_suffix=$RANDOM_SUFFIX"
        else
            log_warning "Cannot plan VMs without foundation outputs"
        fi
    else
        log_info "Skipping VM planning - foundations not deployed"
    fi
}

clean_logs_command() {
    log_step "Cleaning old log files"
    
    if [[ -d "$LOG_DIR" ]]; then
        local count=$(find "$LOG_DIR" -name "*.log" -type f | wc -l)
        if [[ $count -gt 0 ]]; then
            find "$LOG_DIR" -name "*.log" -type f -delete
            log_success "Removed $count log files"
        else
            log_info "No log files to clean"
        fi
    else
        log_info "Log directory doesn't exist"
    fi
}

ssh_keygen_command() {
    log_step "Generating SSH keys for demo"
    
    if [[ -f "$PRIVATE_KEY_PATH" ]]; then
        log_warning "SSH key already exists: $PRIVATE_KEY_PATH"
        echo -n "Overwrite? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Keeping existing SSH key"
            return 0
        fi
    fi
    
    log_info "Generating new SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -C "ansible-demo-$(date +%Y%m%d)" -N ""
    
    if [[ -f "$PRIVATE_KEY_PATH" ]]; then
        chmod 600 "$PRIVATE_KEY_PATH"
        log_success "SSH key generated successfully"
        log_info "Private key: $PRIVATE_KEY_PATH"
        log_info "Public key: $SSH_KEY_PATH"
    else
        log_error "Failed to generate SSH key"
        return 1
    fi
}

password_gen_command() {
    log_step "Generating Windows admin password"
    
    # Generate a strong password
    local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
    
    log_info "Generated password: $password"
    
    # Encode it
    mkdir -p "$(dirname "$ENCODED_FILE")"
    echo "$password" | base64 > "$ENCODED_FILE"
    
    log_success "Password encoded and saved to: $ENCODED_FILE"
    log_warning "Store this password securely: $password"
}

# Main command handler
case "${1:-help}" in
    check)
        check_command
        ;;
    status)
        status_command
        ;;
    connect)
        connect_command
        ;;
    aap-status)
        aap_status_command
        ;;
    aap-logs)
        aap_logs_command
        ;;
    inventory)
        inventory_command
        ;;
    terraform-plan)
        terraform_plan_command
        ;;
    clean-logs)
        clean_logs_command
        ;;
    ssh-keygen)
        ssh_keygen_command
        ;;
    password-gen)
        password_gen_command
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
