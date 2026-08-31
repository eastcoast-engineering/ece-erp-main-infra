resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_ecs_cluster" "api" {
  name = "${local.name_prefix}-api-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${aws_ecr_repository.api.repository_url}:bootstrap"
      essential = true

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = concat(
        [
          {
            name  = "APP_ENV"
            value = var.environment
          },
          {
            name  = "ADDRESS"
            value = "0.0.0.0"
          },
          {
            name  = "PORT"
            value = tostring(var.container_port)
          },
          {
            name  = "DB_HOST"
            value = var.database_host
          },
          {
            name  = "DB_PORT"
            value = tostring(var.database_port)
          },
          {
            name  = "DB_NAME"
            value = var.database_name
          },
          {
            name  = "DB_USER"
            value = var.database_username
          },
          {
            name  = "DB_SSL_MODE"
            value = var.database_ssl_mode
          },
          {
            name  = "AWS_REGION"
            value = var.aws_region
          },
          {
            name  = "AWS_SES_FROM_EMAIL"
            value = var.ses_from_email
          },
          {
            name  = "FILE_STORAGE_DRIVER"
            value = "s3"
          },
          {
            name  = "S3_BUCKET"
            value = aws_s3_bucket.files.id
          },
          {
            name  = "AWS_S3_BUCKET"
            value = aws_s3_bucket.files.id
          },
          {
            name  = "CHAT_S3_BUCKET"
            value = aws_s3_bucket.chat.id
          },
          {
            name  = "CHAT_S3_REGION"
            value = var.aws_region
          },
          {
            name  = "S3_REGION"
            value = var.aws_region
          },
          {
            name  = "S3_PATH_STYLE"
            value = "false"
          }
        ],
        [
          for key, value in var.container_environment : {
            name  = key
            value = value
          }
        ]
      )

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.database_secret_arn}:password::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.runtime.arn}:JWT_SECRET::"
        },
        {
          name      = "EMAIL_ENCRYPTION_KEY"
          valueFrom = "${aws_secretsmanager_secret.runtime.arn}:EMAIL_ENCRYPTION_KEY::"
        },
        {
          name      = "INTERGRATION_ENCRYPTION_KEY"
          valueFrom = "${aws_secretsmanager_secret.runtime.arn}:INTERGRATION_ENCRYPTION_KEY::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.runtime_secrets,
    aws_secretsmanager_secret_version.runtime,
  ]

  tags = local.common_tags
}

resource "aws_ecs_service" "api" {
  name                 = "${local.name_prefix}-api-service"
  cluster              = aws_ecs_cluster.api.id
  task_definition      = aws_ecs_task_definition.api.arn
  desired_count        = var.initial_desired_count
  force_new_deployment = true
  # launch_type     = "FARGATE"

  platform_version = "LATEST"

  health_check_grace_period_seconds = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    capacity_provider = var.environment == "dev" ? "FARGATE_SPOT" : "FARGATE"
    base              = 0
    weight            = 1
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  propagate_tags = "SERVICE"

  depends_on = [aws_lb_listener.https]

  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  tags = local.common_tags
}
