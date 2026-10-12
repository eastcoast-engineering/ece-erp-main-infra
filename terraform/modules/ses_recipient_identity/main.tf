resource "aws_ses_domain_identity" "recipient" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "recipient" {
  domain = aws_ses_domain_identity.recipient.domain
}

resource "aws_ses_domain_identity_verification" "recipient" {
  domain = aws_ses_domain_identity.recipient.domain
}

# Creating an identity requests verification; it does not mark a mailbox verified.
# This adds no send-role permissions and does not change the Mailpit domain/MX.
resource "aws_ses_email_identity" "recipient" {
  for_each = var.email_addresses
  email    = each.value
}
