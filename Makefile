# Default environment
ENV ?= dev

TF_DIR := terraform/environments/$(ENV)
TF_VAR_FILE := $(ENV).tfvars

# Terraform commands
init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan -var-file="$(TF_VAR_FILE)"

apply:
	cd $(TF_DIR) && terraform apply -var-file="$(TF_VAR_FILE)"

destroy:
	cd $(TF_DIR) && terraform destroy -var-file="$(TF_VAR_FILE)"

output:
	cd $(TF_DIR) && terraform output -var-file="$(TF_VAR_FILE)"

fmt:
	terraform fmt -recursive

validate:
	cd $(TF_DIR) && terraform validate

clean:
	cd $(TF_DIR) && rm -rf .terraform .terraform.lock.hcl || powershell -Command "Remove-Item -Recurse -Force .terraform, .terraform.lock.hcl"
