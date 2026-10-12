variable "domain" {
  description = "SES domain identity used as a verified test recipient domain."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$", var.domain))
    error_message = "domain must be a lowercase fully-qualified DNS name."
  }
}

variable "email_addresses" {
  description = "Individual SES sandbox recipients. Each mailbox owner must confirm the AWS verification email."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.email_addresses :
      can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email)) && email == trimspace(email)
    ])
    error_message = "email_addresses must contain valid email addresses without surrounding whitespace."
  }
}
