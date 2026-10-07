data "aws_organizations_organization" "existing" {
  count = var.create_organization ? 0 : 1
}

resource "aws_organizations_organization" "new" {
  count       = var.create_organization ? 1 : 0
  feature_set = var.feature_set
}

locals {
  organization_id = var.create_organization ? aws_organizations_organization.new[0].id : data.aws_organizations_organization.existing[0].id
  root_id         = var.create_organization ? aws_organizations_organization.new[0].roots[0].id : data.aws_organizations_organization.existing[0].roots[0].id
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each = { for ou in var.organizations : ou.ou_name => ou }

  name      = each.key
  parent_id = local.root_id
}

locals {
  accounts_flat = flatten([
    for org in var.organizations : [
      for acc in org.accounts : {
        ou_name = org.ou_name
        name    = acc.name
        email   = acc.email
        role    = acc.role
      }
    ]
  ])
}

resource "aws_organizations_account" "accounts" {
  for_each = {
    for acc in local.accounts_flat :
    "${acc.ou_name}-${acc.email}" => acc
  }

  name      = each.value.name
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.ou[each.value.ou_name].id
  role_name = each.value.role

  lifecycle {
    # AWS cannot return role_name after account creation/import.
    ignore_changes = [role_name]

    # Never accidentally remove or replace an AWS account.
    prevent_destroy = true
  }
}
