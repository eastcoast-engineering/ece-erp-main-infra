output "frontend_github_role_arn" {
  value = module.frontend_oidc.role_arn
}

output "frontend_bucket_name" {
  value = module.frontend.bucket_name
}

output "frontend_cloudfront_distribution_id" {
  value = module.frontend.cloudfront_distribution_id
}

# output "backend_api_url" {
#   value = module.backend.api_url
# }

# output "backend_github_role_arn" {
#   value = module.backend_oidc.role_arn
# }

# output "backend_ecr_repository_name" {
#   value = module.backend.ecr_repository_name
# }

# output "backend_ecs_cluster_name" {
#   value = module.backend.ecs_cluster_name
# }

# output "backend_ecs_service_name" {
#   value = module.backend.ecs_service_name
# }

# output "backend_task_definition_family" {
#   value = module.backend.ecs_task_definition_family
# }

# output "backend_container_name" {
#   value = module.backend.ecs_container_name
# }

# output "database_endpoint" {
#   value = module.database.endpoint
# }

# output "database_secret_arn" {
#   description = "RDS-managed Secrets Manager ARN containing database credentials."
#   value       = module.database.master_user_secret_arn
# }

# output "backend_storage_bucket_name" {
#   value = module.backend.storage_bucket_name
# }

# output "backend_chat_storage_bucket_name" {
#   value = module.backend.chat_storage_bucket_name
# }

output "backend_parameter_arns" {
  description = "SSM SecureString parameter ARNs reserved for the production backend."
  value       = module.backend_secrets.parameter_arns
}

output "root_zone_name_servers" {
  value = module.workwife_dns.name_servers
}

output "mailpit_web_url" {
  value = module.mailpit.web_url
}

output "mailpit_smtp_hostname" {
  value = module.mailpit.smtp_hostname
}

output "mailpit_instance_id" {
  value = module.mailpit.instance_id
}

output "mailpit_admin_username" {
  value = var.mailpit_admin_username
}

output "mailpit_ui_accounts_parameter_name" {
  value = module.mailpit_secrets.parameter_names["UI_ACCOUNTS"]
}

output "mailpit_prod_ses_verification_token" {
  value = module.mailpit_ses_identity.verification_token
}

output "mailpit_prod_ses_dkim_tokens" {
  value = module.mailpit_ses_identity.dkim_tokens
}
