output "identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.postgres.identifier
}


output "address" {
  description = "PostgreSQL hostname."
  value       = aws_db_instance.postgres.address
}


output "endpoint" {
  description = "PostgreSQL hostname and port."
  value       = aws_db_instance.postgres.endpoint
}


output "port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.postgres.port
}


output "database_name" {
  description = "Initial PostgreSQL database name."
  value       = var.database_name
}


output "database_username" {
  description = "PostgreSQL master username."
  value       = var.database_username
}


output "master_user_secret_arn" {
  description = "Database credentials secret ARN. RDS-managed when rotation is enabled and Terraform-managed when rotation is disabled."

  value = local.database_secret_arn
}


output "credentials" {
  description = "PostgreSQL connection credentials when publicly_accessible is true."

  value = var.publicly_accessible ? {
    identifier = aws_db_instance.postgres.identifier

    host     = aws_db_instance.postgres.address
    endpoint = aws_db_instance.postgres.endpoint
    port     = aws_db_instance.postgres.port
    database = var.database_name

    username = var.database_username
    password = local.effective_database_password

    secret_arn = local.database_secret_arn

    password_rotation_enabled = var.password_rotation_enabled

    ssl_mode = "require"
  } : null

  sensitive = true
}