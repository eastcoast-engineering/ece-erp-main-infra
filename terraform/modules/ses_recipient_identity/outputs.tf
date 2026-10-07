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
