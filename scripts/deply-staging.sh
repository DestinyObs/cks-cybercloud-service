#!/bin/bash
set -e

echo "🚀 Deploying NAAS Production Infrastructure - Staging Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if Ansible is installed
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please configure AWS credentials."
        exit 1
    fi
    
    print_status "Prerequisites check passed ✅"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd infrastructure/live/staging
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Generate Ansible inventory
    print_status "Generating Ansible inventory..."
    terraform output -raw ansible_inventory > ../../../playbooks/inventory/hosts.yaml
    
    cd ../../..
}

# Configure nodes with Ansible
configure_nodes() {
    print_status "Configuring nodes with Ansible..."
    
    cd playbooks
    
    # Wait for instances to be ready
    print_status "Waiting for instances to be ready (30 seconds)..."
    sleep 30
    
    # Run Ansible playbook
    print_status "Running Ansible playbook..."
    ansible-playbook -i inventory/hosts.yaml site.yaml
    
    cd ..
}

# Main deployment flow
main() {
    print_status "Starting NAAS Production Infrastructure Deployment - Staging"
    
    check_prerequisites
    deploy_infrastructure
    configure_nodes
    
    print_status "🎉 Deployment completed successfully!"
    print_status "Your Kubernetes cluster is now ready."
    print_warning "Don't forget to:"
    echo "  1. Save the kubeconfig from the master node"
    echo "  2. Configure kubectl on your local machine"
    echo "  3. Test the cluster with 'kubectl get nodes'"
}

# Execute main function
main "$@"

# scripts/destroy-staging.sh
#!/bin/bash
set -e

echo "🔥 Destroying NAAS Production Infrastructure - Staging Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirmation prompt
confirm_destruction() {
    print_warning "⚠️  You are about to DESTROY the staging infrastructure!"
    print_warning "This action cannot be undone."
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_status "Destruction cancelled."
        exit 0
    fi
}

# Destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying infrastructure with Terraform..."
    
    cd infrastructure/live/staging
    
    # Initialize Terraform (in case it's not initialized)
    terraform init
    
    # Destroy infrastructure
    print_status "Destroying Terraform infrastructure..."
    terraform destroy -auto-approve
    
    cd ../../..
}

# Main destruction flow
main() {
    confirm_destruction
    destroy_infrastructure
    
    print_status "🗑️  Infrastructure destroyed successfully!"
}

# Execute main function
main "$@"

# Makefile
.PHONY: help init plan apply destroy staging-deploy staging-destroy prod-deploy prod-destroy clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init           - Initialize Terraform for both environments"
	@echo "  staging-plan   - Plan staging infrastructure"
	@echo "  staging-apply  - Apply staging infrastructure"
	@echo "  staging-deploy - Full staging deployment (Terraform + Ansible)"
	@echo "  staging-destroy- Destroy staging infrastructure"
	@echo "  prod-plan      - Plan production infrastructure"
	@echo "  prod-apply     - Apply production infrastructure"
	@echo "  prod-deploy    - Full production deployment (Terraform + Ansible)"
	@echo "  prod-destroy   - Destroy production infrastructure"
	@echo "  clean          - Clean temporary files"
