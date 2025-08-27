.PHONY: help init staging-plan staging-apply staging-deploy staging-destroy prod-plan prod-apply prod-deploy prod-destroy clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init           - Initialize Terraform for both environments"
	@echo "  staging-plan   - Plan staging infrastructure"
	@echo "  staging-apply  - Apply staging infrastructure"
	@echo "  staging-deploy - Full staging deployment"
	@echo "  staging-destroy- Destroy staging infrastructure"
	@echo "  prod-plan      - Plan production infrastructure"
	@echo "  prod-apply     - Apply production infrastructure"
	@echo "  prod-deploy    - Full production deployment"
	@echo "  prod-destroy   - Destroy production infrastructure"
	@echo "  clean          - Clean temporary files"

# Staging environment
staging-plan:
	cd infrastructure/live/staging && terraform init && terraform plan

staging-apply:
	cd infrastructure/live/staging && terraform init && terraform apply

staging-deploy:
	cd infrastructure/live/staging && terraform init && terraform apply

staging-destroy:
	cd infrastructure/live/staging && terraform destroy

# Production environment
prod-plan:
	cd infrastructure/live/prod && terraform init && terraform plan

prod-apply:
	cd infrastructure/live/prod && terraform init && terraform apply

prod-deploy:
	cd infrastructure/live/prod && terraform init && terraform apply

prod-destroy:
	cd infrastructure/live/prod && terraform destroy

# Utility targets
init:
	cd infrastructure/live/staging && terraform init
	cd infrastructure/live/prod && terraform init

clean:
	find . -name "*.tfplan" -delete
	find . -name ".terraform.lock.hcl" -delete
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true