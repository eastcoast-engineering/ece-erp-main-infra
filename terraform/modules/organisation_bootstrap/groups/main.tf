data "aws_ssoadmin_instances" "sso" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.sso.identity_store_ids[0]
  sso_instance_arn  = data.aws_ssoadmin_instances.sso.arns[0]
}

resource "aws_identitystore_group" "groups" {
  for_each = { for g in var.groups : g.name => g }

  identity_store_id = local.identity_store_id
  display_name      = each.key
}

resource "aws_ssoadmin_permission_set" "permission_sets" {
  for_each = { for g in var.groups : g.name => g }

  instance_arn     = local.sso_instance_arn
  name             = each.key
  session_duration = "PT4H"
}

locals {
  group_policy_pairs = flatten([
    for group in var.groups : [
      for policy_arn in group.policy_arns : {
        group_name = group.name
        policy_arn = policy_arn
      }
    ]
  ])
}

resource "aws_ssoadmin_managed_policy_attachment" "policy_attachments" {
  for_each = {
    for pair in local.group_policy_pairs :
    "${pair.group_name}-${basename(pair.policy_arn)}" => pair
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.permission_sets[each.value.group_name].arn
  managed_policy_arn = each.value.policy_arn
}


locals {
  group_names = toset([
    for group in var.groups :
    group.name
  ])

  # Both inputs to setproduct are known from configuration.
  # No AWS-generated IDs are used as for_each keys.
  group_account_map = {
    for pair in setproduct(
      local.group_names,
      var.account_names
    ) :

    "${pair[0]}-${pair[1]}" => {
      group_name   = pair[0]
      account_name = pair[1]
    }
  }
}

resource "aws_ssoadmin_account_assignment" "group_assignments" {
  for_each = local.group_account_map

  instance_arn = local.sso_instance_arn

  permission_set_arn = aws_ssoadmin_permission_set.permission_sets[
    each.value.group_name
  ].arn

  principal_type = "GROUP"

  principal_id = aws_identitystore_group.groups[
    each.value.group_name
  ].group_id

  target_type = "AWS_ACCOUNT"

  target_id = var.account_ids[
    each.value.account_name
  ]
}
