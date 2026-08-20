locals {
  frontend_domain    = "${var.sub_domain}.${var.root_domain}"
  backend_api_domain = "api.${var.sub_domain}.${var.root_domain}"
}

module "slave_dns" {
  source = "../../modules/slave_dns"

  subdomain = local.frontend_domain

  alias_records = [
    {
      name     = local.frontend_domain
      dns_name = module.frontend.cloudfront_domain
      zone_id  = module.frontend.cloudfront_zone_id
    }
  ]
}

module "frontend" {
  source = "../../modules/frontend_infrastructure"

  domain_name    = local.frontend_domain
  environment    = var.environment
  hosted_zone_id = module.slave_dns.zone_id
}

module "frontend_oidc" {
  source = "../../modules/oidc"

  project_name    = "quotashark"
  environment     = var.environment
  deployment_type = "frontend"

  github_repo = var.frontend_github_repo
  branch      = var.frontend_github_branch

  github_subject_override = (
    var.frontend_github_subject_override
  )

  frontend_bucket_arn = module.frontend.bucket_arn

  cloudfront_distribution_arn = (
    module.frontend.cloudfront_distribution_arn
  )
}

module "backend_network" {
  source = "../../modules/backend_network"

  project_name   = "quotashark"
  environment    = var.environment
  vpc_cidr       = var.backend_vpc_cidr
  container_port = var.backend_container_port

  api_public        = var.api_public
  api_public_cidrs  = var.api_public_cidrs
  api_private_cidrs = var.api_private_cidrs

  database_public       = var.database_public
  database_public_cidrs = var.database_public_cidrs
}

module "database" {
  source = "../../modules/database"

  project_name = "quotashark"
  environment  = var.environment

  public_subnet_ids   = module.backend_network.public_subnet_ids
  private_subnet_ids  = module.backend_network.private_subnet_ids
  security_group_id   = module.backend_network.database_security_group_id
  publicly_accessible = var.database_public

  database_name     = var.database_name
  database_username = var.database_username

  password_rotation_enabled = var.database_password_rotation_enabled
  database_password         = var.database_password

  engine_version = var.database_engine_version
  instance_class = var.database_instance_class

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage

  backup_retention_days = var.database_backup_retention_days
  multi_az              = var.database_multi_az

  deletion_protection = var.database_deletion_protection
  skip_final_snapshot = var.database_skip_final_snapshot
  apply_immediately   = var.database_apply_immediately
}


module "backend" {
  source = "../../modules/backend_deployment"

  project_name = "quotashark"
  environment  = var.environment
  aws_region   = var.aws_region

  domain_name           = local.backend_api_domain
  public_hosted_zone_id = module.slave_dns.zone_id
  api_public            = var.api_public

  vpc_id                          = module.backend_network.vpc_id
  public_subnet_ids               = module.backend_network.public_subnet_ids
  private_subnet_ids              = module.backend_network.private_subnet_ids
  load_balancer_security_group_id = module.backend_network.load_balancer_security_group_id
  ecs_security_group_id           = module.backend_network.ecs_security_group_id

  database_host       = module.database.address
  database_port       = module.database.port
  database_name       = module.database.database_name
  database_username   = module.database.database_username
  database_secret_arn = module.database.master_user_secret_arn
  database_ssl_mode   = var.database_ssl_mode

  storage_bucket_name          = var.backend_storage_bucket_name
  chat_storage_bucket_name     = var.backend_chat_storage_bucket_name
  storage_cors_allowed_origins = var.backend_storage_cors_allowed_origins
  secret_recovery_window_days  = var.backend_secret_recovery_window_days

  container_port            = var.backend_container_port
  health_check_path         = var.backend_health_check_path
  task_cpu                  = var.backend_task_cpu
  task_memory               = var.backend_task_memory
  initial_desired_count     = var.backend_initial_desired_count
  container_environment     = var.backend_container_environment
  ecr_force_delete          = true
  enable_container_insights = false
}

module "backend_oidc" {
  source = "../../modules/oidc"

  project_name    = "quotashark"
  environment     = var.environment
  deployment_type = "backend"
  deployment_name = "backend"

  github_repo             = var.backend_github_repo
  branch                  = var.backend_github_branch
  github_subject_override = var.backend_github_subject_override

  ecr_repository_arn              = module.backend.ecr_repository_arn
  ecs_cluster_arn                 = module.backend.ecs_cluster_arn
  ecs_service_arn                 = module.backend.ecs_service_arn
  ecs_task_definition_arn_pattern = module.backend.ecs_task_definition_arn_pattern
  ecs_task_execution_role_arn     = module.backend.ecs_task_execution_role_arn
  ecs_task_role_arn               = module.backend.ecs_task_role_arn
}
