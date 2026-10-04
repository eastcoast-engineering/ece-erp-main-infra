variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment used for resource names and tags."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the instance when reading SSM parameters."
  type        = string
}

variable "domain_name" {
  description = "Public Mailpit web and inbound-email hostname."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$", var.domain_name))
    error_message = "domain_name must be a lowercase fully-qualified DNS name."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 hosted-zone ID that owns the Mailpit hostname."
  type        = string
}

variable "instance_type" {
  description = "ARM64 EC2 instance type for Mailpit."
  type        = string
  default     = "t4g.nano"
}

variable "ui_accounts_parameter_arn" {
  description = "ARN of the SSM SecureString holding the JSON map of Mailpit UI accounts."
  type        = string
}

variable "ui_accounts_parameter_name" {
  description = "Name of the SSM SecureString holding the JSON map of Mailpit UI accounts."
  type        = string
}

variable "mailpit_version" {
  description = "Pinned Mailpit release."
  type        = string
  default     = "v1.31.4"
}

variable "mailpit_archive_sha256" {
  description = "SHA-256 checksum for the pinned Linux ARM64 Mailpit archive."
  type        = string
  default     = "010a346a8b9d454f6fa22d4fd2dbd5bf5eb7104688412b9c130d0ba33a3579c4"
}

variable "caddy_version" {
  description = "Pinned Caddy release used for HTTPS termination."
  type        = string
  default     = "2.11.7"
}

variable "caddy_archive_sha256" {
  description = "SHA-256 checksum for the pinned Linux ARM64 Caddy archive."
  type        = string
  default     = "d8fc6d179a5d283028a472a5618564f6ad8a86fed513e64f032b3b0b7cc45e42"
}

variable "max_messages" {
  description = "Maximum number of captured messages retained by Mailpit."
  type        = number
  default     = 5000

  validation {
    condition     = var.max_messages > 0
    error_message = "max_messages must be greater than zero."
  }
}

variable "max_age" {
  description = "Maximum age of captured messages."
  type        = string
  default     = "30d"

  validation {
    condition     = can(regex("^[1-9][0-9]*[hd]$", var.max_age))
    error_message = "max_age must use Mailpit's positive hour/day format, for example 36h or 30d."
  }
}

variable "tags" {
  description = "Additional tags applied to Mailpit resources."
  type        = map(string)
  default     = {}
}
