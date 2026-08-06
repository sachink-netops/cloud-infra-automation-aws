# cloud-infra-automation-aws
Production-grade AWS infrastructure bootstrap using Terraform + Ansible. Provisions VPC, subnets, security groups, and EC2 instances with automated configuration (users, hardening, Nginx). Demonstrates IaC, remote state (S3+DynamoDB), dynamic inventory, pre-commit hooks, and CI/CD. Built for DevOps/Platform/SRE portfolios.

# 🚀 Cloud Infra + Config Bootstrap

**Terraform + Ansible | AWS | DevOps Portfolio Project**

[![CI](https://github.com/yourusername/cloud-infra-ansible-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/cloud-infra-ansible-bootstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-%3E%3D2.16-EE0000?logo=ansible)](https://www.ansible.com/)

---

## 📋 Overview

This project provisions a hardened, internet-facing web tier on AWS using **Terraform** (VPC, subnets, security groups, EC2) and configures it with **Ansible** (users, packages, baseline hardening, Nginx). It demonstrates production-ready Infrastructure as Code (IaC) and Configuration Management practices.

### ✨ What This Solves

Replaces manual EC2 builds and SSH-and-bash configuration with a **repeatable, version-controlled pipeline** that enforces security baselines and ships a working Nginx web server. Perfect for demonstrating DevOps skills to recruiters.

---

## 🏗️ Architecture

<img width="1548" height="439" alt="AWS infra deployment" src="https://github.com/user-attachments/assets/ba286df8-0ee2-4ddc-b008-9f777cade3fd" />


### Key Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **VPC** | Terraform | Isolated network with public subnets across 2 AZs |
| **Security Groups** | Terraform | Firewall rules (SSH restricted, HTTP/HTTPS open) |
| **EC2 Instances** | Terraform | Amazon Linux 2 with IMDSv2, encrypted EBS |
| **Remote State** | S3 + DynamoDB | Secure, locked state storage for team collaboration |
| **Configuration** | Ansible | Idempotent roles for hardening and Nginx |
| **Dynamic Inventory** | Ansible + jq | Auto-generated from Terraform outputs |
| **CI/CD** | GitHub Actions | Automated linting, validation, and planning |

---

## 🚀 Quick Start

### Prerequisites

- **AWS Account** with permissions for VPC, EC2, S3, DynamoDB
- **Terraform** >= 1.9.0
- **Ansible** >= 2.16
- **Python 3** + pipx
- **jq** (for inventory generation)

```bash
# Install tooling
pipx install pre-commit tflint ansible-lint
brew install jq  # macOS
sudo apt install jq  # Ubuntu/Debian
```<img width="1548" height="439" alt="AWS infra deployment" src="https://github.com/user-attachments/assets/58606d3c-3212-45a0-b2db-6ad87a30410c" />


### 1. Clone and Setup

```bash
git clone https://github.com/yourusername/cloud-infra-ansible-bootstrap.git
cd cloud-infra-ansible-bootstrap
```

### 2. Create Remote State Backend (One-Time Setup)

```bash
cd terraform/backend
terraform init
terraform apply -var="project=portfolio" -var="environment=dev"
```

**Note the output:** `state_bucket_name` and `dynamodb_table_name`

### 3. Configure Backend

Update `terraform/environments/dev/backend.tf`:

```hcl
backend "s3" {
  bucket         = "portfolio-tfstate-dev"  # Your bucket from step 2
  key            = "dev/terraform.tfstate"
  region         = "us-west-2"
  dynamodb_table = "portfolio-tflocks-dev"  # Your table from step 2
  encrypt        = true
}
```

### 4. Configure Variables

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
# Your project name
project = "portfolio-dev"

# SSH CIDR - Get your public IP: curl https://checkip.amazonaws.com
ssh_cidr_blocks = ["YOUR_IP/32"]  # CRITICAL: Replace this!

# Your SSH public key
public_key = "ssh-ed25519 AAAA... YOUR_KEY ..."
```

### 5. Provision Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 6. Generate Ansible Inventory

```bash
cd ../../..
./scripts/bootstrap.sh  # Or manually:

terraform -chdir=terraform/environments/dev output -json web_instance_public_ips | \
  jq -r '...' > ansible/inventory/ansible_inventory.json
```

### 7. Configure Instances with Ansible

```bash
cd ansible
ansible-playbook -i inventory/dynamic_aws.yml playbooks/site.yml
```

### 8. Verify

Open `http://<PUBLIC_IP>` in your browser (get IPs from `terraform output`).

---

## 📁 Project Structure

