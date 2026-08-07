#!/usr/bin/env bash
# =============================================================================
# Bootstrap Script: Complete Infrastructure Provisioning
# =============================================================================
# This script orchestrates the entire provisioning process:
# 1. Initializes and applies Terraform
# 2. Generates Ansible inventory from Terraform outputs
# 3. Runs Ansible playbooks to configure instances
#
# Usage: ./scripts/bootstrap.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Terraform and Ansible directories
TF_DIR="$PROJECT_ROOT/terraform/environments/dev"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Ansible
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI is not installed. Some features may not work."
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install it (required for inventory generation)."
        exit 1
    fi
    
    log_success "All prerequisites are installed."
}

# =============================================================================
# Terraform Provisioning
# =============================================================================

provision_terraform() {
    log_info "Provisioning infrastructure with Terraform..."
    
    cd "$TF_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -input=false
    
    # Plan infrastructure
    log_info "Planning infrastructure changes..."
    terraform plan -out=tfplan -input=false
    
    # Apply infrastructure
    log_info "Applying infrastructure (this may take 5-10 minutes)..."
    terraform apply -input=false tfplan
    
    log_success "Terraform provisioning complete!"
    
    # Return to project root
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Generate Ansible Inventory
# =============================================================================

generate_inventory() {
    log_info "Generating Ansible inventory from Terraform outputs..."
    
    cd "$TF_DIR"
    
    # Get public IPs from Terraform
    PUBLIC_IPS=$(terraform output -json web_instance_public_ips)
    
    # Generate JSON inventory for Ansible
    echo "$PUBLIC_IPS" | jq -r '
      .web_instance_public_ips as $ips |
      {
        "all": {
          "children": {
            "web_servers": {
              "hosts": (
                $ips | to_entries | map({
                  (.value): {
                    "public_ip": .value,
                    "ansible_host": .value,
                    "ansible_user": "ec2-user",
                    "ansible_connection": "ssh",
                    "ansible_ssh_private_key_file": "~/.ssh/id_ed25519",
                    "ansible_python_interpreter": "/usr/bin/python3"
                  }
                }) | add
              )
            }
          }
        }
      }
    ' > "$ANSIBLE_DIR/inventory/ansible_inventory.json"
    
    log_success "Ansible inventory generated at: $ANSIBLE_DIR/inventory/ansible_inventory.json"
    
    # Display inventory summary
    log_info "Inventory summary:"
    cat "$ANSIBLE_DIR/inventory/ansible_inventory.json" | jq '.all.children.web_servers.hosts | keys'
    
    # Return to project root
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Ansible Configuration
# =============================================================================

configure_ansible() {
    log_info "Configuring instances with Ansible..."
    
    cd "$ANSIBLE_DIR"
    
    # Run the site playbook
    log_info "Running site playbook..."
    ansible-playbook -i inventory/dynamic_aws.yml playbooks/site.yml
    
    log_success "Ansible configuration complete!"
    
    # Return to project root
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo "========================================"
    echo "DevOps Portfolio Project - Bootstrap"
    echo "========================================"
    echo ""
    
    check_prerequisites
    
    echo ""
    log_info "Starting full bootstrap process..."
    echo ""
    
    provision_terraform
    echo ""
    
    generate_inventory
    echo ""
    
    configure_ansible
    echo ""
    
    log_success "========================================="
    log_success "Bootstrap Complete!"
    log_success "========================================="
    log_success ""
    log_success "Your web servers are now running at:"
    terraform -chdir="$TF_DIR" output -json web_instance_public_ips | jq -r '.web_instance_public_ips[]'
    log_success ""
    log_success "Next steps:"
    log_success "1. Open http://<PUBLIC_IP> in your browser"
    log_success "2. SSH: ssh -i ~/.ssh/id_ed25519 ec2-user@<PUBLIC_IP>"
    log_success "3. Explore the project structure on GitHub"
    log_success ""
}

# Run main function
main "$@"
