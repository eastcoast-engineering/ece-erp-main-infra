variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "root_domain" {
  description = "Root production domain."
  type        = string
  default     = "workwife.app"
}

variable "frontend_github_repo" {
  description = "GitHub repository for the frontend website."
  type        = string
}

variable "frontend_github_branch" {
  description = "Frontend branch allowed to deploy to production."
  type        = string
  default     = "main"
}

variable "backend_github_repo" {
  description = "GitHub repository containing the Actix backend."
  type        = string
}

variable "backend_github_branch" {
  description = "Backend branch allowed to deploy to production."
  type        = string
  default     = "main"
}

variable "backend_github_subject_override" {
  description = "Optional exact backend GitHub OIDC subject."
  type        = string
  default     = null
  nullable    = true
}

variable "records" {
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
}

variable "delegations" {
  type = list(object({
    name = string
    ns   = list(string)
  }))
}

variable "backend_vpc_cidr" {
  description = "Production backend VPC CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "api_public" {
  description = "Whether api.workwife.app is public."
  type        = bool
  default     = true
}

variable "api_public_cidrs" {
  description = "CIDRs allowed to reach the public API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_private_cidrs" {
  description = "Additional CIDRs allowed to reach an internal API."
  type        = list(string)
  default     = []
}

variable "backend_container_port" {
  description = "Actix container port."
  type        = number
  default     = 8080
}

variable "backend_health_check_path" {
  description = "Actix health-check path."
  type        = string
  default     = "/health"
}

variable "backend_task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "backend_task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "backend_initial_desired_count" {
  description = "Initial task count before the first GitHub image deployment."
  type        = number
  default     = 0
}

variable "backend_container_environment" {
  description = "Additional non-sensitive backend environment variables."
  type        = map(string)
  default     = {}
}

variable "backend_parameter_store_secrets" {
  description = "Sensitive backend environment values stored as SSM SecureString parameters."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "database_public" {
  description = "Whether production PostgreSQL is publicly addressable."
  type        = bool
  default     = false
}

variable "database_public_cidrs" {
  description = "CIDRs allowed to connect directly to public PostgreSQL."
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
  description = "Optional globally unique production backend file bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_chat_storage_bucket_name" {
  description = "Optional globally unique production chat attachment bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_storage_cors_allowed_origins" {
  description = "Production browser origins allowed to use presigned S3 uploads."
  type        = list(string)
  default     = ["https://workwife.app", "https://www.workwife.app"]
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
  default = 100
}

variable "database_backup_retention_days" {
  type    = number
  default = 7
}

variable "database_multi_az" {
  type    = bool
  default = false
}

variable "database_deletion_protection" {
  type    = bool
  default = true
}

variable "database_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "database_apply_immediately" {
  type    = bool
  default = false
}

variable "frontend_github_subject_override" {
  description = "Exact GitHub OIDC subject for the frontend repository."
  type        = string
  default     = null
  nullable    = true
}

variable "database_password_rotation_enabled" {
  description = "Whether RDS should manage and rotate the database master password."
  type        = bool
  default     = true
}


variable "database_password" {
  description = "Static database password used when database_password_rotation_enabled is false."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
