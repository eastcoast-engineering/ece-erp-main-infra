locals {
  account_names = toset(flatten([
    for organization in var.organizations : [
      for account in organization.accounts :
      account.name
    ]
  ]))
}

module "org" {
  source              = "../../modules/organisation_bootstrap/org"
  organizations       = var.organizations
  create_organization = var.create_organization
  feature_set         = var.feature_set
}

module "groups" {
  source = "../../modules/organisation_bootstrap/groups"

  groups        = var.groups
  account_names = local.account_names
  account_ids   = module.org.accounts
}

module "users" {
  source      = "../../modules/organisation_bootstrap/users"
  users       = var.users
  account_ids = module.org.accounts
  group_ids   = module.groups.group_ids
}
