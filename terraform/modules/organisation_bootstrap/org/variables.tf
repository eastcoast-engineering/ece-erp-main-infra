variable "aws_region" {
  description = "Region for the Organizations API calls (must be us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "create_organization" {
  description = "Create the AWS Organization only for an empty management account. Existing deployments use false."
  type        = bool
  default     = false
}

variable "feature_set" {
  description = "Organizations feature set"
  type        = string
  default     = "ALL"
}

variable "organizations" {
  description = "List of OUs and accounts to create dynamically"
  type = list(object({
    ou_name = string
    accounts = list(object({
      name  = string
      email = string
      role  = optional(string, "OrganizationAccountAccessRole")
    }))
  }))
}
