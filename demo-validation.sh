#!/bin/bash
# ===================================================================
# Demo Environment Validation Functions
# Comprehensive checks to prevent demo failures
# ===================================================================

# Source the config
source "$(dirname "$0")/demo-config.env"

# Validation Functions
validate_azure_cli() {
    log_step "Validating Azure CLI setup"
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not installed"
        return 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure CLI. Run: az login"
        return 1
    fi
    
    local subscription_id=$(az account show --query id -o tsv)
    log_success "Azure CLI ready. Subscription: $subscription_id"
    return 0
}

validate_terraform() {
    log_step "Validating Terraform setup"
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not installed"
        return 1
    fi
    
    local tf_version=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    log_success "Terraform ready. Version: $tf_version"
    return 0
}

validate_ansible() {
    log_step "Validating Ansible setup"
    
    if ! command -v ansible &> /dev/null && ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible not installed"
        return 1
    fi
    
    local ansible_version=$(ansible --version 2>/dev/null | head -n1 || echo "ansible-playbook available")
    log_success "Ansible ready. $ansible_version"
    return 0
}

validate_ssh_keys() {
    log_step "Validating SSH key setup"
    
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_error "SSH public key not found: $SSH_KEY_PATH"
        log_info "Generate with: ssh-keygen -t rsa -b 4096 -f $PRIVATE_KEY_PATH -C 'ansible-demo'"
        return 1
    fi
    
    if [[ ! -f "$PRIVATE_KEY_PATH" ]]; then
        log_error "SSH private key not found: $PRIVATE_KEY_PATH"
        return 1
    fi
    
    # Check key permissions
    local key_perms=$(stat -f "%OLp" "$PRIVATE_KEY_PATH" 2>/dev/null || stat -c "%a" "$PRIVATE_KEY_PATH" 2>/dev/null)
    if [[ "$key_perms" != "600" ]]; then
        log_warning "Private key permissions should be 600, currently $key_perms"
        log_info "Fix with: chmod 600 $PRIVATE_KEY_PATH"
    fi
    
    log_success "SSH keys found and accessible"
    return 0
}

validate_secrets() {
    log_step "Validating secrets"
    
    if [[ ! -f "$ENCODED_FILE" ]]; then
        log_warning "Windows admin password file not found: $ENCODED_FILE"
        log_info "Create with: echo 'YourPassword' | base64 > $ENCODED_FILE"
        return 1
    fi
    
    # Test if the file is readable and contains data
    if [[ ! -s "$ENCODED_FILE" ]]; then
        log_error "Password file is empty: $ENCODED_FILE"
        return 1
    fi
    
    log_success "Secrets file found"
    return 0
}

validate_aap_installer() {
    log_step "Validating AAP installer"
    
    if [[ ! -f "$INSTALLER_PATH" ]]; then
        log_warning "AAP installer not found: $INSTALLER_PATH"
        log_info "Download from: https://access.redhat.com/downloads/content/480/"
        log_info "Place in: downloads/"
        return 1
    fi
    
    # Check if it's a valid tar.gz file
    if ! tar -tzf "$INSTALLER_PATH" &> /dev/null; then
        log_error "AAP installer appears corrupted: $INSTALLER_PATH"
        return 1
    fi
    
    local file_size=$(du -h "$INSTALLER_PATH" | cut -f1)
    log_success "AAP installer found ($file_size)"
    return 0
}

validate_terraform_state() {
    log_step "Checking Terraform state"
    
    local foundations_state="terraform/foundations/terraform.tfstate"
    
    if [[ -f "$foundations_state" ]]; then
        log_info "Existing Terraform state found (will be auto-checked during deployment)"
    else
        log_info "No existing Terraform state found (fresh deployment)"
    fi
    
    return 0
}

# Run all validations
validate_all() {
    log_info "Running comprehensive validation for demo environment"
    local errors=0
    
    validate_azure_cli || ((errors++))
    validate_terraform || ((errors++))
    validate_ansible || ((errors++))
    validate_ssh_keys || ((errors++))
    validate_secrets || ((errors++))
    validate_aap_installer || ((errors++))
    validate_terraform_state || ((errors++))
    
    if [[ $errors -eq 0 ]]; then
        log_success "All validations passed! Environment ready for deployment 🚀"
        return 0
    else
        log_error "$errors validation(s) failed. Please fix the issues above."
        return 1
    fi
}

# If script is run directly, run all validations
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_all
fi
