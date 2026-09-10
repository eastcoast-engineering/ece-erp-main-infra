environment = "dev"
root_domain = "workwife.app"
sub_domain  = "dev"

frontend_github_repo             = "eastcoast-engineering/ece-erp-main-frontend"
frontend_github_branch           = "dev"
frontend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-erp-main-frontend@1157935426:ref:refs/heads/dev"

backend_github_repo             = "eastcoast-engineering/ece-erp-main-backend"
backend_github_branch           = "dev"
backend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-erp-main-backend@1141383024:ref:refs/heads/dev"

api_public        = true
backend_vpc_cidr  = "10.50.0.0/16"
api_public_cidrs  = ["0.0.0.0/0"]
api_private_cidrs = []

backend_container_port        = 8080
backend_health_check_path     = "/health"
backend_task_cpu              = 512
backend_task_memory           = 1024
backend_initial_desired_count = 1

backend_container_environment = {
  RUST_LOG                                     = "debug"
  AWS_SES_FROM_NAME                            = "Workwife"
  ACCESS_TOKEN_EXPIRATION_IN_MINUTE            = "15"
  REFRESH_TOKEN_EXPIRATION_IN_DAYS             = "1"
  REMEMBER_ME_REFRESH_TOKEN_EXPIRATION_IN_DAYS = "30"
  PASSWORD_RESET_EXPIRATION_IN_HOURS           = "24"
  RESEND_FROM_EMAIL                            = "onboarding@resend.dev"
  FRONTEND_BASE_URL                            = "https://dev.workwife.app"
  FRONTEND_OAUTH_CALLBACK_URL                  = "https://dev.workwife.app/auth/login"
  OAUTH_GOOGLE_CLIENT_ID                       = "459345544672-in05gmjmjh76ggrm1me75t70hsh6e52n.apps.googleusercontent.com"
  OAUTH_GOOGLE_REDIRECT_URI                    = "https://api.dev.workwife.app/auth/oauth2/google/callback"
  OAUTH_LINKEDIN_CLIENT_ID                     = "77ghsbh5oh9jcw"
  OAUTH_LINKEDIN_REDIRECT_URI                  = "https://api.dev.workwife.app/auth/oauth2/linkedin/callback"
  COUNTRY_STATE_CITY_API_URL                   = "https://api.countrystatecity.in/v1"
  FIREBASE_PROJECT_ID                          = "workwife-be805"
}

database_public = true

# When database_public is true, use a precise address such as ["203.0.113.10/32"].
database_public_cidrs = [
  "104.28.160.62/32",
  "102.64.68.146/32",
  "104.28.164.87/32"
]

database_name                      = "quotashark"
database_username                  = "quotashark_admin"
database_engine_version            = "16"
database_instance_class            = "db.t4g.micro"
database_allocated_storage         = 20
database_max_allocated_storage     = 0
database_backup_retention_days     = 0
database_multi_az                  = false
database_deletion_protection       = false
database_skip_final_snapshot       = true
database_apply_immediately         = true
database_password_rotation_enabled = false
