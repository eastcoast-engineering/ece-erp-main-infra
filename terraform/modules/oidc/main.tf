locals {
  project_slug = trim(
    replace(lower(var.project_name), "/[^a-z0-9_-]+/", "-"),
    "-"
  )

  environment_slug = trim(
    replace(lower(var.environment), "/[^a-z0-9_-]+/", "-"),
    "-"
  )

  branch_slug = trim(
    replace(lower(var.branch), "/[^a-z0-9_-]+/", "-"),
    "-"
  )

  deployment_slug = var.deployment_name == null ? null : trim(
    replace(lower(var.deployment_name), "/[^a-z0-9_-]+/", "-"),
    "-"
  )

  name_parts = concat(
    [local.project_slug, local.environment_slug],
    local.deployment_slug == null ? [] : [local.deployment_slug],
    [local.branch_slug]
  )

  resource_name_prefix = join("-", local.name_parts)

  role_name = substr(
    "${local.resource_name_prefix}-github-deploy",
    0,
    64
  )

  policy_name = substr(
    "${local.resource_name_prefix}-github-deploy-policy",
    0,
    128
  )

  github_subject = var.github_subject_override != null ? var.github_subject_override : (
    "repo:${var.github_repo}:ref:refs/heads/${var.branch}"
  )

  frontend_bucket_arn         = var.frontend_bucket_arn != null ? var.frontend_bucket_arn : "*"
  frontend_objects_arn        = var.frontend_bucket_arn != null ? "${var.frontend_bucket_arn}/*" : "*"
  cloudfront_distribution_arn = var.cloudfront_distribution_arn != null ? var.cloudfront_distribution_arn : "*"
  ecr_repository_arn          = var.ecr_repository_arn != null ? var.ecr_repository_arn : "*"
  ecs_service_arn             = var.ecs_service_arn != null ? var.ecs_service_arn : "*"
  ecs_cluster_arn             = var.ecs_cluster_arn != null ? var.ecs_cluster_arn : "*"
  ecs_task_definition_arn     = var.ecs_task_definition_arn_pattern != null ? var.ecs_task_definition_arn_pattern : "*"
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn != null ? var.ecs_task_execution_role_arn : "*"
  ecs_task_role_arn           = var.ecs_task_role_arn != null ? var.ecs_task_role_arn : "*"
  cloudwatch_log_group_arn    = var.cloudwatch_log_group_arn != null ? var.cloudwatch_log_group_arn : "*"

  common_tags = merge(
    {
      Project        = var.project_name
      Environment    = var.environment
      DeploymentType = var.deployment_type
      ManagedBy      = "Terraform"
    },
    var.tags
  )
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid     = "AllowGitHubActions"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  description        = "GitHub ${var.deployment_type} deployment role for ${var.github_repo}:${var.branch}"

  tags = local.common_tags
}

data "aws_iam_policy_document" "frontend_deployment" {
  count = var.deployment_type == "frontend" ? 1 : 0

  statement {
    sid    = "ListFrontendBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [local.frontend_bucket_arn]
  }

  statement {
    sid    = "ManageFrontendObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [local.frontend_objects_arn]
  }

  statement {
    sid    = "ManageCloudFrontInvalidations"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
    ]

    resources = [local.cloudfront_distribution_arn]
  }
}

data "aws_iam_policy_document" "backend_deployment" {
  count = var.deployment_type == "backend" ? 1 : 0

  statement {
    sid       = "GetECRAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushBackendImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [local.ecr_repository_arn]
  }

  statement {
    sid    = "ManageTaskDefinitionRevisions"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "DeployBackendService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]

    resources = [local.ecs_service_arn]
  }

  statement {
    sid     = "RunDatabaseMigrations"
    effect  = "Allow"
    actions = ["ecs:RunTask"]

    resources = [local.ecs_task_definition_arn]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [local.ecs_cluster_arn]
    }
  }

  statement {
    sid       = "ObserveMigrationTasks"
    effect    = "Allow"
    actions   = ["ecs:DescribeTasks"]
    resources = ["*"]
  }

  statement {
    sid     = "ReadBackendTaskLogs"
    effect  = "Allow"
    actions = ["logs:GetLogEvents"]

    resources = ["${local.cloudwatch_log_group_arn}:log-stream:*"]
  }

  statement {
    sid     = "PassECSTaskRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      local.ecs_task_execution_role_arn,
      local.ecs_task_role_arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

locals {
  deployment_policy_json = var.deployment_type == "frontend" ? (
    data.aws_iam_policy_document.frontend_deployment[0].json
  ) : data.aws_iam_policy_document.backend_deployment[0].json
}

resource "aws_iam_policy" "github_oidc_policy" {
  name        = local.policy_name
  description = "GitHub ${var.deployment_type} deployment policy for ${var.github_repo}:${var.branch}"
  policy      = local.deployment_policy_json

  tags = local.common_tags

  lifecycle {
    precondition {
      condition = var.deployment_type != "frontend" || (
        var.frontend_bucket_arn != null &&
        var.cloudfront_distribution_arn != null
      )

      error_message = "frontend_bucket_arn and cloudfront_distribution_arn are required for frontend deployment roles."
    }

    precondition {
      condition = var.deployment_type != "backend" || (
        var.ecr_repository_arn != null &&
        var.ecs_cluster_arn != null &&
        var.ecs_service_arn != null &&
        var.ecs_task_definition_arn_pattern != null &&
        var.ecs_task_execution_role_arn != null &&
        var.ecs_task_role_arn != null
      )

      error_message = "ecr_repository_arn, ecs_cluster_arn, ecs_service_arn, ecs_task_definition_arn_pattern, ecs_task_execution_role_arn, and ecs_task_role_arn are required for backend deployment roles."
    }
  }
}

resource "aws_iam_role_policy_attachment" "github_oidc_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.github_oidc_policy.arn
}
