output "parameter_arns" {
  description = "Environment-variable name to SSM SecureString ARN mapping."
  value = {
    for key, parameter in aws_ssm_parameter.backend : key => parameter.arn
  }
}

output "parameter_names" {
  description = "Environment-variable name to SSM SecureString parameter-name mapping."
  value = {
    for key, parameter in aws_ssm_parameter.backend : key => parameter.name
  }
}
