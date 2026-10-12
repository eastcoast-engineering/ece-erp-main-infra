output "arn" {
  value = aws_ses_domain_identity.recipient.arn
}

output "domain" {
  value = aws_ses_domain_identity.recipient.domain
}

output "verification_token" {
  value = aws_ses_domain_identity.recipient.verification_token
}

output "dkim_tokens" {
  value = aws_ses_domain_dkim.recipient.dkim_tokens
}

output "email_identity_arns" {
  description = "ARNs of the individually verified sandbox recipient identities."
  value       = [for identity in aws_ses_email_identity.recipient : identity.arn]
}
