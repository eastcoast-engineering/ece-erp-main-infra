# Workwife infrastructure and deployment

This repository provisions the frontend and backend runtime for Workwife in
two separate AWS organisation accounts. Terraform owns infrastructure; GitHub
Actions owns application image/file deployment.

| Environment | AWS account | Frontend | Backend API | Local profile |
|---|---:|---|---|---|
| Development | `964308144304` | `https://dev.workwife.app` | `https://api.dev.workwife.app` | `ece-dev` |
| Production | `905611588718` | `https://workwife.app` | `https://api.workwife.app` | `ece-prod` |
| Local | none | `http://localhost:4200` | `http://127.0.0.1:8080` | none |

The organisation-account Terraform is now included under
`terraform/environments/organisation` and
`terraform/modules/organisation_bootstrap`. It was recovered from the sibling
`infra-core` checkout (remote repository `ece-core-infra`). The original source
and state remain intact. This repository owns both account-bootstrap source and
application infrastructure.

## Architecture

Each environment has its own state, network, data, and deployment identities:

```text
GitHub backend workflow (OIDC)
  -> ECR immutable image
  -> one-off ECS/Fargate migration task
  -> ECS/Fargate API service
       -> private RDS PostgreSQL
       -> private, versioned S3 file bucket
       -> separate private, versioned chat attachment bucket
       -> SES

GitHub frontend workflow (OIDC)
  -> private frontend S3 bucket
  -> CloudFront
```

Terraform creates:

- Route 53, ACM, CloudFront, and the frontend S3 bucket;
- a dedicated VPC with public API/ECS subnets and private database subnets;
- an encrypted RDS PostgreSQL instance;
- an ECR repository, ECS cluster/service/task definition, ALB, and DNS;
- a private, encrypted, versioned backend file bucket with presigned-upload
  CORS and blocked public access;
- a separate private, encrypted, versioned chat attachment bucket with the
  same public-access block and presigned-upload CORS controls;
- least-privilege ECS task/execution policies for S3, SES, and secrets;
- separate GitHub OIDC roles for frontend and backend deployments.
- a production-account Mailpit test mailbox on the smallest ARM EC2 instance,
  with Route 53 MX/A records and an authenticated HTTPS UI.

CloudWatch task logging defaults to disabled, but development explicitly enables
it with one-day retention so migration, E2E, and service failures are diagnosable.
Container Insights remains disabled. The normal API service runs one task.

RDS owns the database master password with
`manage_master_user_password = true`. The credential JSON is stored in the
RDS-managed Secrets Manager secret and injected into ECS as `DB_PASSWORD`.
All other backend secrets are stored as standard-tier SSM SecureString
parameters by the reusable `terraform/modules/secret_management` module and
injected into ECS by ARN. Sensitive values are never passed through GitHub
Actions.

## Runtime configuration contract

The ECS task receives non-secret database parts as `DB_HOST`, `DB_PORT`,
`DB_NAME`, `DB_USER`, and `DB_SSL_MODE`. Secrets Manager injects
`DB_PASSWORD`. Both the API and migration binaries safely construct the same
percent-encoded PostgreSQL URL.

The task also receives:

- `ADDRESS=0.0.0.0` and `PORT=8080`;
- `FILE_STORAGE_DRIVER=s3`;
- `S3_BUCKET`, `AWS_S3_BUCKET`, `S3_REGION`, and `S3_PATH_STYLE=false`;
- `CHAT_S3_BUCKET` and `CHAT_S3_REGION` for chat attachments only;
- `JWT_SECRET`, encryption keys, OAuth client secrets, the country provider
  key, and Firebase service-account JSON from SSM Parameter Store;
- a Terraform-verified environment sender domain, DKIM, custom MAIL FROM DNS,
  a separately verified sender mailbox, and `AWS_SES_FROM_EMAIL`;
- `APP_ENV` and `RUST_LOG` for environment-specific behavior.

The ECS task role supplies AWS credentials through the default AWS provider
chain. Do not add static access keys to Terraform, ECS, or GitHub.

Plain backend settings belong in each environment's tracked `*.tfvars` file.
Secret values belong in the adjacent gitignored `*.secrets.auto.tfvars` file;
copy the committed `.example` file when bootstrapping an environment. Terraform
automatically loads the secret file from the environment directory. These
values are sensitive in Terraform output but are still present in encrypted
remote state, so state access must remain restricted. The Firebase JSON is
passed through `GOOGLE_APPLICATION_CREDENTIALS_JSON`; no credential file is
baked into the container image.

SES retains the environment identities `dev.workwife.app` and `workwife.app`.
The current testing sender in both environments is
`noreply@mailpit.workwife.app`, covered by the separately verified Mailpit domain
identity. Domain verification and send permissions are configured independently
in each AWS account; a verified recipient does not authorize an unrelated sender.

Individual sandbox testing recipients are declared in each environment's
`ses_test_recipient_emails` set. The shared recipient-identity module creates
their SES email identities. In development, the backend task policy includes
these verified recipient identity ARNs because SES v2 evaluates them during
`SendEmail`. That statement requires `ses:FromAddress` to equal the configured
`AWS_SES_FROM_EMAIL`; it does not allow the task to send *from* a test mailbox.
Each mailbox owner must click the AWS verification link for each
account/region before SES can deliver registration or recovery messages there.
Terraform creation means verification **requested**, not verified. Keep automated
test users on Mailpit; these personal addresses are optional manual testers.

Check status without sending another verification email:

```bash
aws ses get-identity-verification-attributes --profile ece-dev --region us-east-1 \
  --identities mryoungtommy@gmail.com tom.kidumbuyo@gmail.com angeladolberth@gmail.com
```

Use `ece-prod` for the separate production-account check. If an identity already
exists outside Terraform, import it into
`module.mailpit_ses_identity.aws_ses_email_identity.recipient["EMAIL"]` before
applying; do not delete/recreate an already verified mailbox to adopt it.

## Shared test mailbox

All automated and manual test email addresses should use
`<anything>@mailpit.workwife.app`. Route 53 publishes an MX record for that
subdomain, and the production-account Mailpit instance captures every matching
recipient without relaying messages onward. Open the shared inbox at
`https://mailpit.workwife.app` and sign in through the browser login page. The
generated administrator username is `workwife`; engineers use their configured
email address.

Mailpit UI accounts are declared in the gitignored
`terraform/environments/prod/prod.secrets.auto.tfvars` file as the sensitive
`mailpit_ui_accounts` map. Terraform combines those engineer accounts with the
generated `workwife` administrator and stores only the resulting JSON in the
standard-tier SSM SecureString `/workwife/prod/mailpit/ui_accounts`. The host
refreshes its authentication file every 30 minutes. Add or remove an engineer
in that map and apply the production Terraform; never place a real password in
the tracked example file.

Retrieve the generated `workwife` password only when needed:

```bash
aws-vault exec ece-prod -- aws ssm get-parameter \
  --name /workwife/prod/mailpit/ui_accounts \
  --with-decryption \
  --query Parameter.Value \
  --output text | jq -r '.workwife'
```

Mailpit runs on an on-demand `t4g.nano` with an encrypted 8 GiB root volume.
There is no load balancer, NAT gateway, SSH ingress, or CloudWatch log
ingestion. Caddy terminates HTTPS automatically, SSM Session Manager is the
only administrative entry point, and Mailpit accepts SMTP only for
`@mailpit.workwife.app`. Captured messages are testing data, capped at 5,000
messages and retained for at most 30 days; they are not a production archive.

The same domain is verified as an SES identity in both the development and
production AWS accounts. This allows either sandboxed SES account to deliver
test messages to any `<anything>@mailpit.workwife.app` recipient. Terraform
publishes both accounts' verification and DKIM records in the production Route
53 zone. The MX record still points directly to Mailpit and must not be replaced
with an SES inbound receipt endpoint.

## Prerequisites

- Terraform 1.5 or newer;
- AWS CLI and `aws-vault`;
- active `ece-dev` and `ece-prod` AWS IAM Identity Center sessions;
- access to the two remote-state buckets;
- maintainer access to the backend and frontend GitHub repositories.

Confirm identities before planning or applying:

```bash
aws-vault exec ece-dev -- aws sts get-caller-identity
aws-vault exec ece-prod -- aws sts get-caller-identity
```

The account returned for each profile must match the table above. If a session
is expired, complete the device authorization shown by `aws-vault` and rerun
the identity command.

## Terraform workflow

### AWS organisation recovery

The management-account stack uses account `058755926944`, profile `ece-root`,
and the original state at
`s3://ece-tfstate-058755926944/infra-core/dev/terraform.tfstate`. Resource module
names are preserved, so moving source does not recreate accounts or SSO users.
The recovered configuration was checked against that state and produced a
no-change plan. The actual `organisation.tfvars` is gitignored to avoid
publishing engineer identities in this public infrastructure repository.

```bash
aws-vault exec ece-root -- terraform -chdir=terraform/environments/organisation init
aws-vault exec ece-root -- terraform -chdir=terraform/environments/organisation plan -var-file=organisation.tfvars
```

For recovery on another machine, restore the variable file from the private
`ece-core-infra` source or management state, then review the plan. Keep the state
key unchanged; do not run the old and new checkouts concurrently. AWS accounts
have `prevent_destroy`. Setting `create_organization=true` supports an empty
management account without first evaluating an absent-organisation data source.

Initial management-account access, the remote-state buckets, and enabling the
organization instance of IAM Identity Center are bootstrap prerequisites.
AWS documents enabling that organization instance through the management
console: https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-and-orgs.html
After that, Terraform provisions OUs/accounts, SSO users/groups/permission sets,
and the separate dev/prod application stacks. No organisational changes were
applied while recovering this source.

State is separated by account:

- dev: `s3://ece-dev-terraform-state-964308144304/infrastructure/terraform.tfstate`
- prod: `s3://ece-prod-terraform-state-905611588718/infrastructure/terraform.tfstate`

Initialize and validate:

```bash
aws-vault exec ece-dev -- make init ENV=dev
aws-vault exec ece-dev -- make validate ENV=dev

aws-vault exec ece-prod -- make init ENV=prod
aws-vault exec ece-prod -- make validate ENV=prod
```

Review plans independently:

```bash
aws-vault exec ece-dev -- make plan ENV=dev
aws-vault exec ece-prod -- make plan ENV=prod
```

Apply only after confirming that the plan targets the expected account. A
domain cutover intentionally replaces the frontend bucket and ACM certificates
and retires the old public hosted zones, but it must not replace RDS, the
backend file bucket, the VPC, or the ECS cluster/service:

```bash
aws-vault exec ece-dev -- make apply ENV=dev
aws-vault exec ece-prod -- make apply ENV=prod
```

Production has database deletion protection and final snapshots enabled.
Backend file buckets use `force_destroy = false`, so Terraform cannot silently
delete stored files.

## First backend deployment

Terraform deliberately creates the ECS service with desired count zero. This
avoids trying to pull the placeholder `:bootstrap` image before GitHub has
published a real image.

After applying Terraform, collect the outputs:

```bash
aws-vault exec ece-dev -- terraform -chdir=terraform/environments/dev output
aws-vault exec ece-prod -- terraform -chdir=terraform/environments/prod output
```

Set these GitHub repository variables in the backend repository:

| Variable | Terraform output |
|---|---|
| `DEV_BACKEND_AWS_ROLE_ARN` | dev `backend_github_role_arn` |
| `PROD_BACKEND_AWS_ROLE_ARN` | prod `backend_github_role_arn` |
| `DEV_BACKEND_ECR_REPOSITORY` | dev `backend_ecr_repository_name` |
| `DEV_BACKEND_ECS_CLUSTER` | dev `backend_ecs_cluster_name` |
| `DEV_BACKEND_ECS_SERVICE` | dev `backend_ecs_service_name` |
| `DEV_BACKEND_TASK_FAMILY` | dev `backend_task_definition_family` |
| `DEV_BACKEND_CONTAINER_NAME` | dev `backend_container_name` |

Production backend resource variables use the corresponding production
outputs when that stack is enabled. The production backend is currently
disabled in `terraform/environments/prod/main.tf`; do not enable it as an
incidental part of a frontend-only domain cutover.

Set these GitHub repository variables in the frontend repository:

| Variable | Terraform output |
|---|---|
| `DEV_FRONTEND_AWS_ROLE_ARN` | dev `frontend_github_role_arn` |
| `DEV_FRONTEND_CLOUDFRONT_DISTRIBUTION_ID` | dev `frontend_cloudfront_distribution_id` |
| `PROD_FRONTEND_AWS_ROLE_ARN` | prod `frontend_github_role_arn` |
| `PROD_FRONTEND_CLOUDFRONT_DISTRIBUTION_ID` | prod `frontend_cloudfront_distribution_id` |

No database password, AWS key, JWT secret, or encryption key belongs in GitHub.

Run the dev backend workflow manually once, or push to `dev`. After validation,
merge to `main` to run production. Each backend workflow:

1. assumes its environment-specific OIDC role;
2. builds the API and migration binaries into one immutable image;
3. pushes the commit SHA tag to that account's ECR repository;
4. registers a new task-definition revision;
5. runs `workwife-migration up` as a one-off Fargate task in the service
   network and stops on a non-zero exit code;
6. updates the API service only after migrations succeed;
7. waits for ECS stability and probes `/health` over the public API URL.

This ordering prevents an application revision from serving against an older
schema. Never move migrations to a public runner with direct database access;
RDS stays private and the migration task runs inside the VPC.

## Frontend environments

Frontend builds use three explicit API targets:

- local `environment.ts`: `http://localhost:8080`;
- dev `environment.dev.ts`: `https://api.dev.workwife.app`;
- prod `environment.prod.ts`: `https://api.workwife.app`.

The dev frontend workflow builds with Angular's `deployment-dev`
configuration. The production workflow uses `production`. This keeps browser
assets and backend deployments visibly separate while retaining parallel
dev/prod naming and OIDC ownership.

## Local backend

Local development may continue to use a single `DATABASE_URL` and local file
storage. The split `DB_*` contract is an alternative used by ECS and can also
be tested locally.

```bash
cd ../backend
cargo run -p app-server
```

The local API must answer:

```bash
curl -i http://127.0.0.1:8080/health
```

## Verification after an apply

For each environment, check:

```bash
curl --fail https://api.dev.workwife.app/health
curl --fail https://api.workwife.app/health
```

Then verify in AWS:

- the ECS service has one running task and no deployment rollback event;
- the most recent one-off migration task exited with code zero;
- the ALB target is healthy;
- RDS is available and not public;
- the RDS master secret and backend SSM SecureString parameters exist;
- both the backend file bucket and dedicated chat attachment bucket have public
  access blocked and versioning enabled;
- an authenticated presigned upload can write and read a temporary object;
- when `enable_cloudwatch_logs` is enabled, CloudWatch logs contain no
  missing-variable, database, S3, or migration errors.

## Rotation and recovery

- Database credentials remain in the RDS-managed secret. ECS reads the current
  value whenever a new task starts.
- To rotate a backend parameter, update its environment's gitignored
  `*.secrets.auto.tfvars`, review and apply the Terraform plan, then redeploy the
  service. Rotating JWT/encryption keys can invalidate sessions or make old
  encrypted values unreadable, so coordinate it as an application migration.
- S3 versioning protects overwritten objects. Deletion is still an explicit
  application operation and the bucket cannot be force-destroyed.
- Never commit `.tfstate`, AWS credentials, exported secret values, or generated
  task-definition JSON.

## Remaining live-deployment steps

If this repository has only been validated locally, the remaining work is
operational rather than code generation:

1. refresh both `aws-vault` SSO sessions;
2. verify the registrar delegates `workwife.app` to the production Route 53
   hosted zone and that the root zone delegates `dev.workwife.app` to dev;
3. run and review the dev plan, then apply it;
4. set the development backend and frontend repository variables from the
   Terraform outputs;
5. run the dev workflows and complete the verification checklist;
6. repeat plan/apply and frontend variables for prod;
7. run the production frontend workflow and verify the public site;
8. enable and deploy the production backend stack separately before expecting
   `https://api.workwife.app` to answer.

Do not apply production merely because validation succeeds. A Terraform plan
is the final authority for changes to already-deployed resources.
