variable "project_name" {
  description = "Project name used in parameter paths and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment used in parameter paths and tags."
  type        = string
}

variable "namespace" {
  description = "Service namespace used in parameter paths and tags."
  type        = string
  default     = "backend"
}

variable "parameter_values" {
  description = "Sensitive service values stored as SSM SecureString parameters."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to managed parameters."
  type        = map(string)
  default     = {}
}
