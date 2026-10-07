data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = substr("${local.name_prefix}-ecs-execution", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "runtime_secrets" {
  statement {
    sid       = "ReadDatabaseSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.database_secret_arn]
  }

  dynamic "statement" {
    for_each = length(var.container_secret_parameters) == 0 ? [] : [1]

    content {
      sid       = "ReadBackendParameters"
      effect    = "Allow"
      actions   = ["ssm:GetParameters"]
      resources = values(var.container_secret_parameters)
    }
  }
}

resource "aws_iam_role_policy" "runtime_secrets" {
  name   = "${local.name_prefix}-runtime-secrets"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.runtime_secrets.json
}

resource "aws_iam_role" "ecs_task" {
  name               = substr("${local.name_prefix}-ecs-task", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "backend_storage" {
  statement {
    sid    = "InspectBackendFileBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.files.arn]
  }

  statement {
    sid    = "ManageBackendFiles"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.files.arn}/*"]
  }

  statement {
    sid    = "InspectChatBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.chat.arn]
  }

  statement {
    sid    = "ManageChatAttachments"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.chat.arn}/*"]
  }
}

resource "aws_iam_role_policy" "backend_storage" {
  name   = "${local.name_prefix}-backend-storage"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.backend_storage.json
}

data "aws_iam_policy_document" "backend_email" {
  statement {
    sid    = "SendApplicationEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = concat([
      aws_ses_domain_identity.sender.arn,
      aws_ses_email_identity.sender.arn,
    ], var.ses_additional_sender_identity_arns)
  }

  dynamic "statement" {
    for_each = length(var.ses_sandbox_recipient_identity_arns) > 0 ? [1] : []
    content {
      sid       = "SendToVerifiedSandboxRecipients"
      effect    = "Allow"
      actions   = ["ses:SendEmail", "ses:SendRawEmail"]
      resources = var.ses_sandbox_recipient_identity_arns

      # SES v2 evaluates a verified recipient email identity as a resource.
      # These ARNs must not authorize sending *from* a test recipient.
      condition {
        test     = "StringEquals"
        variable = "ses:FromAddress"
        values   = [var.ses_from_email]
      }
    }
  }
}

resource "aws_iam_role_policy" "backend_email" {
  name   = "${local.name_prefix}-backend-email"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.backend_email.json
}
