environment = "prod"
root_domain = "quotashark.com"

frontend_github_repo             = "eastcoast-engineering/ece-crm-main-frontend"
frontend_github_branch           = "main"
frontend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-crm-main-frontend@1157935426:ref:refs/heads/main"

backend_github_repo             = "eastcoast-engineering/ece-crm-main-backend"
backend_github_branch           = "main"
backend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-crm-main-backend@1141383024:ref:refs/heads/main"

# For a GitHub repository created after July 15, 2026, set the exact immutable
# subject shown by GitHub, for example:
# backend_github_subject_override = "repo:OWNER@OWNER_ID/REPO@REPO_ID:ref:refs/heads/main"

backend_vpc_cidr = "10.40.0.0/16"

api_public        = true
api_public_cidrs  = ["0.0.0.0/0"]
api_private_cidrs = []

backend_container_port        = 8080
backend_health_check_path     = "/health"
backend_task_cpu              = 512
backend_task_memory           = 1024
backend_initial_desired_count = 1

backend_container_environment = {
  RUST_LOG           = "info"
  AWS_SES_FROM_EMAIL = "noreply@eastcoast.engineering",
  AWS_SES_FROM_NAME  = "Quota Shark"
}

database_public       = false
database_public_cidrs = []

database_name                  = "quotashark"
database_username              = "quotashark_admin"
database_engine_version        = "16"
database_instance_class        = "db.t4g.micro"
database_allocated_storage     = 20
database_max_allocated_storage = 100
database_backup_retention_days = 7
database_multi_az              = false
database_deletion_protection   = true
database_skip_final_snapshot   = false
database_apply_immediately     = false

database_password_rotation_enabled = true

records = [
  {
    name    = "www"
    type    = "CNAME"
    ttl     = 300
    records = ["quotashark.com"]
  }
]

# Replace these values whenever the dev hosted zone is recreated.
delegations = [
  {
    name = "dev.quotashark.com"
    ns = [
      "ns-520.awsdns-01.net",
      "ns-9.awsdns-01.com",
      "ns-1953.awsdns-52.co.uk",
      "ns-1469.awsdns-55.org",
    ]
  }
]