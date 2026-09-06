locals {
  project_slug = trim(replace(lower(var.project_name), "/[^a-z0-9-]+/", "-"), "-")
  environment_slug = trim(
    replace(lower(var.environment), "/[^a-z0-9-]+/", "-"),
    "-"
  )

  parameter_names = nonsensitive(toset(keys(var.parameter_values)))
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "BackendSecrets"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "backend" {
  for_each = local.parameter_names

  name = "/${local.project_slug}/${local.environment_slug}/backend/${lower(each.key)}"
  type = "SecureString"
  tier = "Standard"
  value = sensitive(
    var.parameter_values[each.key]
  )

  tags = merge(local.common_tags, {
    Name = each.key
  })

  lifecycle {
    precondition {
      condition     = trimspace(var.parameter_values[each.key]) != ""
      error_message = "SSM SecureString parameter ${each.key} cannot be empty."
    }
  }
}
