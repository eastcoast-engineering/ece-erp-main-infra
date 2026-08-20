output "api_url" {
  description = "API HTTPS URL."
  value       = "https://${var.domain_name}"
}

output "api_public" {
  description = "Whether the API is public."
  value       = var.api_public
}

output "load_balancer_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.api.dns_name
}

output "ecr_repository_arn" {
  description = "Backend ECR repository ARN."
  value       = aws_ecr_repository.api.arn
}

output "ecr_repository_name" {
  description = "Backend ECR repository name."
  value       = aws_ecr_repository.api.name
}

output "ecr_repository_url" {
  description = "Backend ECR repository URL."
  value       = aws_ecr_repository.api.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.api.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.api.arn
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.api.name
}

output "ecs_service_arn" {
  description = "ECS service ARN."
  value       = local.ecs_service_arn
}

output "ecs_task_definition_family" {
  description = "ECS task definition family."
  value       = aws_ecs_task_definition.api.family
}

output "ecs_task_definition_arn_pattern" {
  description = "ARN pattern for revisions of the API task definition."
  value       = "${aws_ecs_task_definition.api.arn_without_revision}:*"
}

output "ecs_container_name" {
  description = "Actix ECS container name."
  value       = local.container_name
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "Actix task role ARN."
  value       = aws_iam_role.ecs_task.arn
}

output "storage_bucket_name" {
  description = "Private versioned bucket used for backend files."
  value       = aws_s3_bucket.files.id
}

output "storage_bucket_arn" {
  description = "ARN of the private backend file bucket."
  value       = aws_s3_bucket.files.arn
}

output "chat_storage_bucket_name" {
  description = "Private versioned bucket used exclusively for chat attachments."
  value       = aws_s3_bucket.chat.id
}

output "chat_storage_bucket_arn" {
  description = "ARN of the private chat attachment bucket."
  value       = aws_s3_bucket.chat.arn
}

output "runtime_secret_arn" {
  description = "Secrets Manager ARN containing backend runtime cryptographic values."
  value       = aws_secretsmanager_secret.runtime.arn
}
