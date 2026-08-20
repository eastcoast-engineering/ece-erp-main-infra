locals {
  project_slug = trim(
    replace(lower(var.project_name), "/[^a-z0-9-]+/", "-"),
    "-"
  )

  environment_slug = trim(
    replace(lower(var.environment), "/[^a-z0-9-]+/", "-"),
    "-"
  )

  name_prefix = substr(
    "${local.project_slug}-${local.environment_slug}",
    0,
    24
  )

  subnet_ids = (
    var.publicly_accessible
    ? var.public_subnet_ids
    : var.private_subnet_ids
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Database"
    },
    var.tags
  )
}


resource "aws_db_subnet_group" "postgres" {
  name       = "${local.name_prefix}-postgres-subnets"
  subnet_ids = local.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres-subnets"
  })
}


resource "aws_db_instance" "postgres" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username

  # Static password when rotation is disabled.
  password = (
    var.password_rotation_enabled
    ? null
    : var.database_password
  )

  # RDS / Secrets Manager owns the password only when rotation is enabled.
  manage_master_user_password = (
    var.password_rotation_enabled
    ? true
    : null
  )

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible = var.publicly_accessible
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_days
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = (
    var.skip_final_snapshot
    ? null
    : "${local.name_prefix}-postgres-final"
  )

  lifecycle {
    precondition {
      condition = (
        var.password_rotation_enabled ||
        var.database_password != null
      )

      error_message = "database_password must be provided when password_rotation_enabled is false."
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres"
  })
}


# ------------------------------------------------------------
# Static credential secret
# ------------------------------------------------------------
#
# When RDS-managed password rotation is disabled, RDS no longer
# creates a Secrets Manager secret.
#
# We create our own non-rotating secret instead so ECS can keep
# using the exact same database_secret_arn interface.
#

resource "aws_secretsmanager_secret" "postgres_static_master" {
  count = var.password_rotation_enabled ? 0 : 1

  name = "${local.name_prefix}-postgres-static-master"

  # Important when switching between static/managed modes.
  # Otherwise AWS can leave the old secret pending deletion,
  # preventing recreation with the same name.
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres-static-master"
  })
}


resource "aws_secretsmanager_secret_version" "postgres_static_master" {
  count = var.password_rotation_enabled ? 0 : 1

  secret_id = (
    aws_secretsmanager_secret.postgres_static_master[0].id
  )

  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
  })
}


# ------------------------------------------------------------
# RDS-managed credentials
# ------------------------------------------------------------
#
# Only read the RDS-generated secret when:
#
# 1. RDS password management is enabled
# 2. The database is public and we want credentials available
#    through the Terraform output.
#

data "aws_secretsmanager_secret_version" "postgres_master" {
  count = (
    var.password_rotation_enabled &&
    var.publicly_accessible
  ) ? 1 : 0

  secret_id = (
    aws_db_instance.postgres
    .master_user_secret[0]
    .secret_arn
  )

  depends_on = [
    aws_db_instance.postgres
  ]
}


locals {
  managed_master_credentials = (
    length(data.aws_secretsmanager_secret_version.postgres_master) > 0
    ? jsondecode(
      data.aws_secretsmanager_secret_version.postgres_master[0].secret_string
    )
    : null
  )

  effective_database_password = (
    var.password_rotation_enabled
    ? try(local.managed_master_credentials["password"], null)
    : var.database_password
  )

  database_secret_arn = (
    var.password_rotation_enabled
    ? try(
      aws_db_instance.postgres.master_user_secret[0].secret_arn,
      null
    )
    : try(
      aws_secretsmanager_secret.postgres_static_master[0].arn,
      null
    )
  )
}
