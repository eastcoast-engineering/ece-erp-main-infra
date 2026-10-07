variable "aws_region" {
  description = "Region for the Organizations API calls (must be us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "create_organization" {
  type    = bool
  default = false
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

variable "admin_user_ids" {
  description = "Map of admin usernames. Full IAM ARNs will be constructed using root_id."
  type        = map(string)
}

variable "groups" {
  type = list(object({
    name        = string
    policy_arns = list(string)
  }))
}

variable "users" {
  type = map(object({
    groups      = list(string)
    email       = string
    given_name  = string
    family_name = string
  }))
}
