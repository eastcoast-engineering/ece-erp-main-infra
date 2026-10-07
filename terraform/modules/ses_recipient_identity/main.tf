resource "aws_ses_domain_identity" "recipient" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "recipient" {
  domain = aws_ses_domain_identity.recipient.domain
}

resource "aws_ses_domain_identity_verification" "recipient" {
  domain = aws_ses_domain_identity.recipient.domain
}
