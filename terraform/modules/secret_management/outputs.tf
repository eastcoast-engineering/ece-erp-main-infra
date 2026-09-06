output "parameter_arns" {
  description = "Environment-variable name to SSM SecureString ARN mapping for ECS."
  value = {
    for key, parameter in aws_ssm_parameter.backend : key => parameter.arn
  }
}
