#!/bin/bash
# ===================================================================
# Azure Resource Cleanup Helper
# Cleans up existing Azure resources that might conflict with deployment
# ===================================================================

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/demo-config.env"

set -euo pipefail

show_help() {
    cat << 'EOF'
🧹 Azure Resource Cleanup Helper

USAGE:
  ./cleanup-azure.sh [OPTIONS]

OPTIONS:
  --resource-group RG_NAME    Clean specific resource group
  --all-demo-resources        Clean all cert-renewal-demo resources
  --list                      List existing demo resources
  --help                      Show this help

EXAMPLES:
  ./cleanup-azure.sh --list                           # See what exists
  ./cleanup-azure.sh --resource-group cert-renewal-demo-rg  # Clean specific RG
  ./cleanup-azure.sh --all-demo-resources             # Clean all demo RGs

SAFETY:
  - Always lists resources before deletion
  - Requires confirmation before proceeding
  - Only targets demo-related resources

EOF
}

list_demo_resources() {
    log_step "Listing demo-related resources in current subscription"
    
    local subscription=$(az account show --query name -o tsv)
    log_info "Current subscription: $subscription"
    
    echo
    log_info "Resource groups matching 'cert-renewal-demo':"
    az group list --query "[?contains(name, 'cert-renewal-demo')].{Name:name, Location:location, State:properties.provisioningState}" -o table 2>/dev/null || echo "None found"
    
    echo
    log_info "All resources in demo resource groups:"
    local demo_rgs=$(az group list --query "[?contains(name, 'cert-renewal-demo')].name" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$demo_rgs" ]]; then
        for rg in $demo_rgs; do
            echo "📦 Resource Group: $rg"
            az resource list --resource-group "$rg" --query "[].{Name:name, Type:type, Location:location}" -o table 2>/dev/null || echo "  No resources found"
            echo
        done
    else
        echo "No demo resource groups found"
    fi
}

cleanup_resource_group() {
    local rg_name="$1"
    
    log_step "Cleaning up resource group: $rg_name"
    
    # Check if resource group exists
    if ! az group show --name "$rg_name" &>/dev/null; then
        log_info "Resource group '$rg_name' does not exist"
        return 0
    fi
    
    # Show what will be deleted
    log_info "Resources that will be deleted in '$rg_name':"
    az resource list --resource-group "$rg_name" --query "[].{Name:name, Type:type}" -o table
    
    echo
    log_warning "This will DELETE ALL resources in the resource group '$rg_name'"
    echo -n "Continue? (yes/no): "
    read -r response
    
    if [[ "$response" == "yes" ]]; then
        log_info "Deleting resource group '$rg_name'..."
        az group delete --name "$rg_name" --yes --no-wait
        log_success "Resource group '$rg_name' deletion initiated (running in background)"
        log_info "Check status with: az group show --name '$rg_name'"
    else
        log_info "Cleanup cancelled"
    fi
}

cleanup_all_demo_resources() {
    log_step "Cleaning up all demo-related resources"
    
    local demo_rgs=$(az group list --query "[?contains(name, 'cert-renewal-demo')].name" -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$demo_rgs" ]]; then
        log_info "No demo resource groups found"
        return 0
    fi
    
    log_info "Found demo resource groups:"
    for rg in $demo_rgs; do
        echo "  - $rg"
    done
    
    echo
    log_warning "This will DELETE ALL demo-related resource groups and their contents"
    echo -n "Continue? (yes/no): "
    read -r response
    
    if [[ "$response" == "yes" ]]; then
        for rg in $demo_rgs; do
            log_info "Deleting resource group: $rg"
            az group delete --name "$rg" --yes --no-wait
        done
        log_success "All demo resource groups deletion initiated"
        log_info "Deletions are running in background"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main logic
case "${1:-help}" in
    --list)
        list_demo_resources
        ;;
    --resource-group)
        if [[ -z "${2:-}" ]]; then
            log_error "Resource group name required"
            show_help
            exit 1
        fi
        cleanup_resource_group "$2"
        ;;
    --all-demo-resources)
        cleanup_all_demo_resources
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        log_error "Unknown option: ${1:-}"
        echo
        show_help
        exit 1
        ;;
esac
