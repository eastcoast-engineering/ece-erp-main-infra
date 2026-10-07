output "accounts" {
  value = {
    for k, v in aws_organizations_account.accounts :
    v.name => v.id
  }
}

output "root_id" {
  value = local.root_id
}
