environment = "prod"
root_domain = "workwife.app"

mailpit_domain         = "mailpit.workwife.app"
mailpit_instance_type  = "t4g.nano"
mailpit_admin_username = "workwife"
mailpit_max_messages   = 5000
mailpit_max_age        = "30d"

email_domain = "workwife.app"

ses_test_recipient_emails = [
  "mryoungtommy@gmail.com",
  "tom.kidumbuyo@gmail.com",
  "angeladolberth@gmail.com",
]

frontend_github_repo             = "eastcoast-engineering/ece-erp-main-frontend"
frontend_github_branch           = "main"
frontend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-erp-main-frontend@1157935426:ref:refs/heads/main"

backend_github_repo             = "eastcoast-engineering/ece-erp-main-backend"
backend_github_branch           = "main"
backend_github_subject_override = "repo:eastcoast-engineering@247177585/ece-erp-main-backend@1141383024:ref:refs/heads/main"

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
  RUST_LOG                                     = "info"
  AWS_SES_FROM_NAME                            = "Workwife"
  ACCESS_TOKEN_EXPIRATION_IN_MINUTE            = "15"
  REFRESH_TOKEN_EXPIRATION_IN_DAYS             = "1"
  REMEMBER_ME_REFRESH_TOKEN_EXPIRATION_IN_DAYS = "30"
  PASSWORD_RESET_EXPIRATION_IN_HOURS           = "24"
  RESEND_FROM_EMAIL                            = "onboarding@resend.dev"
  FRONTEND_BASE_URL                            = "https://workwife.app"
  FRONTEND_OAUTH_CALLBACK_URL                  = "https://workwife.app/auth/login"
  OAUTH_GOOGLE_CLIENT_ID                       = "459345544672-in05gmjmjh76ggrm1me75t70hsh6e52n.apps.googleusercontent.com"
  OAUTH_GOOGLE_REDIRECT_URI                    = "https://api.workwife.app/auth/oauth2/google/callback"
  OAUTH_LINKEDIN_CLIENT_ID                     = "77ghsbh5oh9jcw"
  OAUTH_LINKEDIN_REDIRECT_URI                  = "https://api.workwife.app/auth/oauth2/linkedin/callback"
  COUNTRY_STATE_CITY_API_URL                   = "https://api.countrystatecity.in/v1"
  FIREBASE_PROJECT_ID                          = "workwife-be805"
}

database_public       = false
database_public_cidrs = []

database_name                  = "workwife"
database_username              = "workwife_admin"
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
    records = ["workwife.app"]
  }
]

# Replace these values whenever the dev hosted zone is recreated.
delegations = [
  {
    name = "dev.workwife.app"
    ns = [
      "ns-318.awsdns-39.com",
      "ns-779.awsdns-33.net",
      "ns-1218.awsdns-24.org",
      "ns-1760.awsdns-28.co.uk",
    ]
  }
]

# SES domain-identity tokens created in the dev account. The prod account owns
# workwife.app DNS, so it publishes both accounts' verification records.
mailpit_dev_ses_verification_tokens = [
  "mrnZnn7h4j39cr4WcyqSz9kFCj2Iy4/j1TqPrHTG7ys=",
]

mailpit_dev_ses_dkim_tokens = [
  "gg4p3b22ogmivl6sk37y4emc3wty553l",
  "rtm3sn2lm4mnld742f4mf57cs3trftt6",
  "qqvmbjdguczwn5ulpem4rumhekgonv3l",
]
