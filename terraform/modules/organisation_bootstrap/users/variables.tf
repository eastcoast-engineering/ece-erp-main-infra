variable "users" {
  type = map(object({
    groups      = list(string)
    email       = string
    given_name  = string
    family_name = string
  }))
}

variable "account_ids" {
  type = map(string)
}

variable "group_ids" {
  type = map(string)
}
