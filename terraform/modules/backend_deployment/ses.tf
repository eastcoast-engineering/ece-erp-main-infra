resource "aws_ses_domain_identity" "sender" {
  domain = var.ses_sender_domain
}

resource "aws_ses_email_identity" "sender" {
  email = var.ses_from_email
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.ses_hosted_zone_id
  name    = "_amazonses.${var.ses_sender_domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.sender.verification_token]
}

resource "aws_ses_domain_identity_verification" "sender" {
  domain = aws_ses_domain_identity.sender.domain

  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_ses_domain_dkim" "sender" {
  domain = aws_ses_domain_identity.sender.domain
}

resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = var.ses_hosted_zone_id
  name    = "${aws_ses_domain_dkim.sender.dkim_tokens[count.index]}._domainkey.${var.ses_sender_domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.sender.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_mail_from" "sender" {
  domain                 = aws_ses_domain_identity.sender.domain
  mail_from_domain       = "mail.${var.ses_sender_domain}"
  behavior_on_mx_failure = "UseDefaultValue"
}

resource "aws_route53_record" "ses_mail_from_mx" {
  zone_id = var.ses_hosted_zone_id
  name    = aws_ses_domain_mail_from.sender.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]
}

resource "aws_route53_record" "ses_mail_from_spf" {
  zone_id = var.ses_hosted_zone_id
  name    = aws_ses_domain_mail_from.sender.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}
