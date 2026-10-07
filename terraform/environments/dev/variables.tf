variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "root_domain" {
  description = "Root domain."
  type        = string
  default     = "workwife.app"
}

variable "email_domain" {
  description = "Root email domain."
  type        = string
  default     = "mailpit.workwife.app"
}

variable "sub_domain" {
  description = "Delegated development subdomain."
  type        = string
  default     = "dev"
}

variable "mailpit_recipient_domain" {
  description = "Shared test-mail domain verified as an SES recipient identity."
  type        = string
  default     = "mailpit.workwife.app"
}

variable "frontend_github_repo" {
  description = "GitHub repository for the frontend website."
  type        = string
}

variable "frontend_github_branch" {
  description = "Frontend branch allowed to deploy to development."
  type        = string
  default     = "dev"
}

variable "frontend_github_subject_override" {
  description = "Optional exact frontend GitHub OIDC subject."
  type        = string
  default     = null
  nullable    = true
}


variable "backend_github_repo" {
  description = "GitHub repository containing the Actix backend."
  type        = string
}

variable "backend_github_branch" {
  description = "Backend branch allowed to deploy to development."
  type        = string
  default     = "dev"
}

variable "backend_github_subject_override" {
  description = "Optional exact backend GitHub OIDC subject."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_vpc_cidr" {
  description = "Development backend VPC CIDR."
  type        = string
  default     = "10.50.0.0/16"
}

variable "api_public" {
  description = "Whether api.dev.workwife.app is public."
  type        = bool
  default     = true
}

variable "api_public_cidrs" {
  description = "CIDRs allowed to reach the public development API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_private_cidrs" {
  description = "Additional CIDRs allowed to reach an internal development API."
  type        = list(string)
  default     = []
}

variable "backend_container_port" {
  type    = number
  default = 8080
}

variable "backend_health_check_path" {
  type    = string
  default = "/health"
}

variable "backend_task_cpu" {
  type    = number
  default = 512
}

variable "backend_task_memory" {
  type    = number
  default = 1024
}

variable "backend_initial_desired_count" {
  type    = number
  default = 0
}

variable "backend_container_environment" {
  type    = map(string)
  default = {}
}

variable "backend_parameter_store_secrets" {
  description = "Sensitive backend environment values stored as SSM SecureString parameters."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "database_public" {
  description = "Whether development PostgreSQL is publicly addressable."
  type        = bool
  default     = false
}

variable "database_public_cidrs" {
  description = "CIDRs allowed to connect directly to public development PostgreSQL."
  type        = list(string)
  default     = []
}

variable "database_name" {
  type    = string
  default = "workwife"
}

variable "database_username" {
  type    = string
  default = "workwife_admin"
}

variable "database_ssl_mode" {
  description = "PostgreSQL SSL mode used by API and migration tasks."
  type        = string
  default     = "require"
}

variable "backend_storage_bucket_name" {
  description = "Optional globally unique development backend file bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_chat_storage_bucket_name" {
  description = "Optional globally unique development chat attachment bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_storage_cors_allowed_origins" {
  description = "Development browser origins allowed to use presigned S3 uploads."
  type        = list(string)
  default     = ["https://dev.workwife.app"]
}

variable "database_engine_version" {
  type    = string
  default = "16"
}

variable "database_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "database_allocated_storage" {
  type    = number
  default = 20
}

variable "database_max_allocated_storage" {
  type    = number
  default = 50
}

variable "database_backup_retention_days" {
  type    = number
  default = 1
}

variable "database_multi_az" {
  type    = bool
  default = false
}

variable "database_deletion_protection" {
  type    = bool
  default = false
}

variable "database_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "database_apply_immediately" {
  type    = bool
  default = true
}

variable "database_password_rotation_enabled" {
  description = "Whether RDS should manage and rotate the database master password."
  type        = bool
  default     = false
}


variable "database_password" {
  description = "Static database password used when database_password_rotation_enabled is false."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
