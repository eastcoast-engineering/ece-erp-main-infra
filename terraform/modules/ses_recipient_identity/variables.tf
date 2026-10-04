variable "domain" {
  description = "SES domain identity used as a verified test recipient domain."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$", var.domain))
    error_message = "domain must be a lowercase fully-qualified DNS name."
  }
}
