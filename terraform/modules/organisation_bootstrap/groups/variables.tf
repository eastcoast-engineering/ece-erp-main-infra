variable "groups" {
  type = list(object({
    name        = string
    policy_arns = list(string)
  }))
}

variable "account_names" {
  description = "Static names of AWS accounts receiving permission sets"
  type        = set(string)
}

variable "account_ids" {
  description = "Map of all AWS account names to IDs to assign permission sets"
  type        = map(string)
}
