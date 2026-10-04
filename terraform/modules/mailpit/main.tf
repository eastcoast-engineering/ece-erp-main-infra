locals {
  project_slug = trim(replace(lower(var.project_name), "/[^a-z0-9-]+/", "-"), "-")
  environment_slug = trim(
    replace(lower(var.environment), "/[^a-z0-9-]+/", "-"),
    "-"
  )
  name_prefix = "${local.project_slug}-${local.environment_slug}-mailpit"
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Mailpit"
    },
    var.tags
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amazon_linux_2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_vpc" "mailpit" {
  cidr_block           = "10.60.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "mailpit" {
  vpc_id = aws_vpc.mailpit.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.mailpit.id
  cidr_block              = "10.60.0.0/28"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mailpit.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mailpit.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "mailpit" {
  name_prefix = "${local.name_prefix}-"
  description = "Public HTTPS and inbound SMTP for Workwife test mail"
  vpc_id      = aws_vpc.mailpit.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "smtp" {
  security_group_id = aws_security_group.mailpit.id
  description       = "Inbound internet email"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 25
  ip_protocol       = "tcp"
  to_port           = 25
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.mailpit.id
  description       = "Caddy ACME challenge and HTTPS redirect"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.mailpit.id
  description       = "Mailpit HTTPS web UI"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.mailpit.id
  description       = "Package downloads, ACME, SSM, DNS, and response traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mailpit" {
  name               = "${local.name_prefix}-instance"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.mailpit.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "read_ui_accounts" {
  statement {
    sid       = "ReadMailpitUiAccounts"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [var.ui_accounts_parameter_arn]
  }
}

resource "aws_iam_role_policy" "read_ui_accounts" {
  name   = "${local.name_prefix}-read-ui-accounts"
  role   = aws_iam_role.mailpit.id
  policy = data.aws_iam_policy_document.read_ui_accounts.json
}

resource "aws_iam_instance_profile" "mailpit" {
  name = "${local.name_prefix}-instance"
  role = aws_iam_role.mailpit.name
}

resource "aws_instance" "mailpit" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_arm64.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mailpit.id]
  iam_instance_profile        = aws_iam_instance_profile.mailpit.name
  monitoring                  = false
  # Account changes are delivered by SSM. Keep user-data updates in place so
  # routine auth/config maintenance does not erase the disposable inbox or
  # force unnecessary ACME certificate reissuance.
  user_data_replace_on_change = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    auth_sync_script = templatefile("${path.module}/sync_auth.sh.tftpl", {
      aws_region                 = var.aws_region
      ui_accounts_parameter_name = var.ui_accounts_parameter_name
    })
    auth_server             = file("${path.module}/auth_server.py")
    caddy_archive_sha256    = var.caddy_archive_sha256
    caddy_version           = var.caddy_version
    domain_name             = var.domain_name
    mailpit_archive_sha256  = var.mailpit_archive_sha256
    mailpit_version         = var.mailpit_version
    max_age                 = var.max_age
    max_messages            = var.max_messages
    smtp_allowed_recipients = "@${replace(var.domain_name, ".", "\\\\.")}$"
  })

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })

  depends_on = [
    aws_iam_role_policy.read_ui_accounts,
    aws_iam_role_policy_attachment.ssm_managed_instance,
    aws_route_table_association.public,
  ]
}

resource "aws_ssm_association" "sync_ui_accounts" {
  name                = "AWS-RunShellScript"
  association_name    = "${local.name_prefix}-sync-ui-accounts"
  schedule_expression = "rate(30 minutes)"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.mailpit.id]
  }

  parameters = {
    commands = "/usr/local/sbin/sync-mailpit-auth"
  }
}

resource "aws_eip" "mailpit" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-ip"
  })
}

resource "aws_eip_association" "mailpit" {
  allocation_id = aws_eip.mailpit.id
  instance_id   = aws_instance.mailpit.id
}

resource "aws_route53_record" "address" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_eip.mailpit.public_ip]
}

resource "aws_route53_record" "inbound_mail" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  records = ["10 ${var.domain_name}."]
}

resource "aws_route53_record" "no_outbound_mail" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 -all"]
}
