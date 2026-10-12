# Default environment (can be overridden: make tp ENV=development)
ENV ?= production
LAMBDA_DIR = ../lambda/reminders

# Install the Lambda's runtime dependencies so archive_file can zip them.
build:
	cd $(LAMBDA_DIR) && npm ci --omit=dev

# Lambda unit tests (pure logic; no AWS access needed)
test:
	cd $(LAMBDA_DIR) && npm ci && npm test

# Terraform Init Workspace
ti:
	terraform init && \
	terraform workspace select -or-create $(ENV)

# Terraform Plan
tp: build ti
	terraform plan -var-file=environment.$(ENV).tfvars -out=$(ENV).plan

# Terraform Apply (saved plan file)
ta: ti
	terraform apply $(ENV).plan

# Terraform Destroy
td: ti
	terraform destroy -var-file=environment.$(ENV).tfvars

# Show current environment
env:
	@echo "Current environment: $(ENV)"
	@echo "Usage: make <target> ENV=<environment>"
	@echo "Example: make tp ENV=production"
