output "instance_id" {
  description = "Mailpit EC2 instance ID."
  value       = aws_instance.mailpit.id
}

output "public_ip" {
  description = "Stable public IPv4 address for Mailpit."
  value       = aws_eip.mailpit.public_ip
}

output "web_url" {
  description = "HTTPS URL for the Mailpit web UI."
  value       = "https://${var.domain_name}"
}

output "smtp_hostname" {
  description = "Public MX/SMTP hostname for captured test email."
  value       = var.domain_name
}
