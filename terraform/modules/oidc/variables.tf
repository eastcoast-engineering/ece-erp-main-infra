variable "project_name" {
  description = "Project name used in IAM resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment, such as dev or prod."
  type        = string
}

variable "deployment_type" {
  description = "Deployment permission set created by this module."
  type        = string

  validation {
    condition     = contains(["frontend", "backend"], var.deployment_type)
    error_message = "deployment_type must be frontend or backend."
  }
}

variable "deployment_name" {
  description = "Optional component added to IAM names. Use backend for the backend role; leave null for the existing frontend role names."
  type        = string
  default     = null
  nullable    = true
}

variable "github_repo" {
  description = "GitHub repository in owner/repository format."
  type        = string
}

variable "branch" {
  description = "GitHub branch allowed to assume this role."
  type        = string
}

variable "github_subject_override" {
  description = "Optional exact GitHub OIDC sub claim. Use for GitHub environments or repositories using immutable owner/repository IDs."
  type        = string
  default     = null
  nullable    = true
}

variable "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN. Required when deployment_type is frontend."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudfront_distribution_arn" {
  description = "Frontend CloudFront distribution ARN. Required when deployment_type is frontend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecr_repository_arn" {
  description = "Backend ECR repository ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_service_arn" {
  description = "Backend ECS service ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_cluster_arn" {
  description = "Backend ECS cluster ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_task_definition_arn_pattern" {
  description = "Backend ECS task-definition revision ARN pattern. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_task_role_arn" {
  description = "ECS application task role ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudwatch_log_group_arn" {
  description = "Backend CloudWatch log group ARN. Required when deployment_type is backend."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional IAM resource tags."
  type        = map(string)
  default     = {}
}
