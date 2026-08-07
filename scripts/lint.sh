#!/usr/bin/env bash
# =============================================================================
# Lint Script: Code Quality Checks
# =============================================================================
# This script runs all linting and validation checks:
# - Terraform fmt (formatting)
# - TFLint (static analysis)
# - Terraform validate
# - Ansible-lint
#
# Usage: ./scripts/lint.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directories
TF_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# =============================================================================
# Terraform Checks
# =============================================================================

check_terraform_fmt() {
    log_info "Checking Terraform formatting..."
    
    cd "$TF_DIR"
    
    if terraform fmt -check -recursive -diff; then
        log_success "Terraform formatting: OK"
    else
        log_error "Terraform formatting issues found. Run 'terraform fmt -recursive' to fix."
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

check_tflint() {
    log_info "Running TFLint..."
    
    cd "$TF_DIR"
    
    if command -v tflint &> /dev/null; then
        if tflint --config=.tflint.hcl; then
            log_success "TFLint: OK"
        else
            log_error "TFLint found issues. Review and fix."
            exit 1
        fi
    else
        log_info "TFLint not installed. Skipping..."
    fi
    
    cd "$PROJECT_ROOT"
}

check_terraform_validate() {
    log_info "Validating Terraform configurations..."
    
    cd "$TF_DIR/environments/dev"
    
    terraform init -backend=false -input=false > /dev/null 2>&1
    
    if terraform validate; then
        log_success "Terraform validation: OK"
    else
        log_error "Terraform validation failed."
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Ansible Checks
# =============================================================================

check_ansible_lint() {
    log_info "Running ansible-lint..."
    
    cd "$ANSIBLE_DIR"
    
    if command -v ansible-lint &> /dev/null; then
        if ansible-lint playbooks/*.yml --exclude=requirements.yml; then
            log_success "Ansible-lint: OK"
        else
            log_error "Ansible-lint found issues. Review and fix."
            exit 1
        fi
    else
        log_info "ansible-lint not installed. Skipping..."
    fi
    
    cd "$PROJECT_ROOT"
}

check_ansible_syntax() {
    log_info "Checking Ansible playbook syntax..."
    
    cd "$ANSIBLE_DIR"
    
    if ansible-playbook -i inventory/dynamic_aws.yml --syntax-check playbooks/site.yml; then
        log_success "Ansible syntax check: OK"
    else
        log_error "Ansible syntax check failed."
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo "========================================"
    echo "Code Quality Checks"
    echo "========================================"
    echo ""
    
    check_terraform_fmt
    echo ""
    
    check_tflint
    echo ""
    
    check_terraform_validate
    echo ""
    
    check_ansible_lint
    echo ""
    
    check_ansible_syntax
    echo ""
    
    log_success "========================================="
    log_success "All checks passed!"
    log_success "========================================="
}

main "$@"
