# main.tf
data "aws_ssoadmin_instances" "this" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  sso_instance_arn  = data.aws_ssoadmin_instances.this.arns[0]
}

# Create users
resource "aws_identitystore_user" "users" {
  for_each = var.users

  identity_store_id = local.identity_store_id
  user_name         = each.value.email
  display_name      = each.key

  emails {
    value = each.value.email
    type  = "work"
  }

  name {
    given_name  = each.value.given_name != "" ? each.value.given_name : each.key
    family_name = each.value.family_name != "" ? each.value.family_name : "User"
  }
}

# Assign users to groups
locals {
  user_group_pairs = flatten([
    for username, u in var.users : [
      for g in u.groups : {
        username   = username
        group_name = g
      }
    ]
  ])
}

resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for pair in local.user_group_pairs :
    "${pair.username}-${pair.group_name}" => pair
  }

  identity_store_id = local.identity_store_id
  group_id          = var.group_ids[each.value.group_name]
  member_id         = aws_identitystore_user.users[each.value.username].user_id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [member_id, group_id]
  }
}
