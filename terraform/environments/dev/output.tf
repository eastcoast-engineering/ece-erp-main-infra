output "frontend_github_role_arn" {
  value = module.frontend_oidc.role_arn
}

output "backend_api_url" {
  value = module.backend.api_url
}

output "backend_github_role_arn" {
  value = module.backend_oidc.role_arn
}

output "backend_ecr_repository_name" {
  value = module.backend.ecr_repository_name
}

output "backend_ecs_cluster_name" {
  value = module.backend.ecs_cluster_name
}

output "backend_ecs_service_name" {
  value = module.backend.ecs_service_name
}

output "backend_task_definition_family" {
  value = module.backend.ecs_task_definition_family
}

output "backend_container_name" {
  value = module.backend.ecs_container_name
}

output "database_endpoint" {
  value = module.database.endpoint
}

output "database_secret_arn" {
  description = "RDS-managed Secrets Manager ARN containing database credentials."
  value       = module.database.master_user_secret_arn
}

output "backend_storage_bucket_name" {
  value = module.backend.storage_bucket_name
}

output "backend_chat_storage_bucket_name" {
  value = module.backend.chat_storage_bucket_name
}

output "backend_parameter_arns" {
  description = "SSM SecureString parameter ARNs injected into the backend."
  value       = module.backend_secrets.parameter_arns
}

output "dev_zone_name_servers" {
  value = module.workwife_dns.name_servers
}

output "frontend_bucket_name" {
  value = module.frontend.bucket_name
}

output "frontend_cloudfront_distribution_id" {
  value = module.frontend.cloudfront_distribution_id
}

output "database_credentials" {
  description = "Development database credentials when database_public is true."

  value = var.database_public ? module.database.credentials : null

  sensitive = true
}
output "mailpit_ses_verification_token" {
  value = module.mailpit_ses_identity.verification_token
}

output "mailpit_ses_dkim_tokens" {
  value = module.mailpit_ses_identity.dkim_tokens
}
