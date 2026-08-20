# Quotashark infrastructure and deployment

This repository provisions the frontend and backend runtime for Quotashark in
two separate AWS organisation accounts. Terraform owns infrastructure; GitHub
Actions owns application image/file deployment.

| Environment | AWS account | Frontend | Backend API | Local profile |
|---|---:|---|---|---|
| Development | `964308144304` | `https://dev.quotashark.com` | `https://api.dev.quotashark.com` | `ece-dev` |
| Production | `905611588718` | `https://quotashark.com` | `https://api.quotashark.com` | `ece-prod` |
| Local | none | `http://localhost:4200` | `http://127.0.0.1:8080` | none |

The organisation accounts were originally created by the sibling
`infra-core` repository. The older `infra-organisation` repository is useful
for DNS history, but this repository is now the application-infrastructure
source of truth.

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
- an ECR repository, ECS cluster/service/task definition, ALB, logs, and DNS;
- a private, encrypted, versioned backend file bucket with presigned-upload
  CORS and blocked public access;
- a separate private, encrypted, versioned chat attachment bucket with the
  same public-access block and presigned-upload CORS controls;
- least-privilege ECS task/execution policies for S3, SES, and secrets;
- separate GitHub OIDC roles for frontend and backend deployments.

RDS owns the database master password with
`manage_master_user_password = true`. The credential JSON is stored in the
RDS-managed Secrets Manager secret and injected into ECS as `DB_PASSWORD`.
Terraform also stores JWT and encryption keys in a separate backend runtime
secret. Sensitive values are never passed through GitHub Actions.

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
- `JWT_SECRET`, `EMAIL_ENCRYPTION_KEY`, and
  `INTERGRATION_ENCRYPTION_KEY` from Secrets Manager;
- `APP_ENV` and `RUST_LOG` for environment-specific behavior.

The ECS task role supplies AWS credentials through the default AWS provider
chain. Do not add static access keys to Terraform, ECS, or GitHub.

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

Apply only after confirming that the plan targets the expected account and
does not replace RDS, either S3 bucket, DNS zones, or certificates:

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

No database password, AWS key, JWT secret, or encryption key belongs in GitHub.

Run the dev backend workflow manually once, or push to `dev`. After validation,
merge to `main` to run production. Each backend workflow:

1. assumes its environment-specific OIDC role;
2. builds the API and migration binaries into one immutable image;
3. pushes the commit SHA tag to that account's ECR repository;
4. registers a new task-definition revision;
5. runs `quotashark-migration up` as a one-off Fargate task in the service
   network and stops on a non-zero exit code;
6. updates the API service only after migrations succeed;
7. waits for ECS stability and probes `/health` over the public API URL.

This ordering prevents an application revision from serving against an older
schema. Never move migrations to a public runner with direct database access;
RDS stays private and the migration task runs inside the VPC.

## Frontend environments

Frontend builds use three explicit API targets:

- local `environment.ts`: `http://localhost:8080`;
- dev `environment.dev.ts`: `https://api.dev.quotashark.com`;
- prod `environment.prod.ts`: `https://api.quotashark.com`.

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
curl --fail https://api.dev.quotashark.com/health
curl --fail https://api.quotashark.com/health
```

Then verify in AWS:

- the ECS service has one running task and no deployment rollback event;
- the most recent one-off migration task exited with code zero;
- the ALB target is healthy;
- RDS is available and not public;
- the RDS master secret and backend runtime secret exist;
- both the backend file bucket and dedicated chat attachment bucket have public
  access blocked and versioning enabled;
- an authenticated presigned upload can write and read a temporary object;
- CloudWatch logs contain no missing-variable, database, S3, or migration
  errors.

## Rotation and recovery

- Database credentials remain in the RDS-managed secret. ECS reads the current
  value whenever a new task starts.
- To rotate backend runtime keys through Terraform, use targeted replacement of
  the relevant `random_password.runtime` resource, review the plan, apply, and
  redeploy the service. Rotating JWT/encryption keys can invalidate sessions or
  make old encrypted values unreadable, so coordinate it as an application
  migration.
- S3 versioning protects overwritten objects. Deletion is still an explicit
  application operation and the bucket cannot be force-destroyed.
- Never commit `.tfstate`, AWS credentials, exported secret values, or generated
  task-definition JSON.

## Remaining live-deployment steps

If this repository has only been validated locally, the remaining work is
operational rather than code generation:

1. refresh both `aws-vault` SSO sessions;
2. run and review the dev plan, then apply it;
3. set `DEV_BACKEND_AWS_ROLE_ARN` from the dev output;
4. run the dev GitHub workflow and complete the verification checklist;
5. repeat plan/apply and the role variable for prod;
6. run the prod workflow and verify the production API.

Do not apply production merely because validation succeeds. A Terraform plan
is the final authority for changes to already-deployed resources.
