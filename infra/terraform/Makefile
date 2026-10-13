# Default environment (can be overridden: make tp ENV=development)
ENV ?= production
LAMBDA_DIR = ../lambda/reminders

# nvm is a shell function, so recipes that use it need bash.
SHELL := /bin/bash
NVM_SH ?= $(HOME)/.nvm/nvm.sh

# Switches to the Node version in the Lambda's .nvmrc when nvm is installed,
# installing it on first use. Without nvm, whatever `node` is on PATH is
# used, and npm warns if it's older than the Lambda runtime.
# --no-use matters: sourcing nvm.sh otherwise runs `nvm use` on the .nvmrc
# itself and fails (exit 3) when the version isn't installed yet.
define use_node
if [ -s "$(NVM_SH)" ]; then . "$(NVM_SH)" --no-use; nvm use >/dev/null || nvm install; fi
endef

# Install the Lambda's runtime dependencies so archive_file can zip them.
build:
	cd $(LAMBDA_DIR) && $(use_node) && npm ci --omit=dev

# Lambda unit tests (pure logic; no AWS access needed)
test:
	cd $(LAMBDA_DIR) && $(use_node) && npm ci && npm test

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
