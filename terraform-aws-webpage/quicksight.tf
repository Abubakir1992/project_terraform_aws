variable "quicksight_email" {
  type        = string
  description = "QuickSight administrator and subscription notification email."
  default     = ""
}
variable "create_quicksight_subscription" {
  type        = bool
  default     = true
  description = "Use false if this AWS account is already subscribed to QuickSight."
}
locals { quicksight_enabled = var.quicksight_email != "" }
resource "aws_quicksight_account_subscription" "moto" {
  count                 = local.quicksight_enabled && var.create_quicksight_subscription ? 1 : 0
  account_name          = "motohaus-${local.suffix}"
  authentication_method = "IAM_AND_QUICKSIGHT"
  edition               = "ENTERPRISE"
  notification_email    = var.quicksight_email
}
resource "aws_quicksight_user" "admin" {
  count         = local.quicksight_enabled ? 1 : 0
  email         = var.quicksight_email
  identity_type = "QUICKSIGHT"
  user_role     = "ADMIN"
  user_name     = "motohaus-admin"
  namespace     = "default"
  depends_on    = [aws_quicksight_account_subscription.moto]
}
resource "aws_quicksight_data_source" "athena" {
  count          = local.quicksight_enabled ? 1 : 0
  data_source_id = "moto-athena"
  name           = "Motohaus anonymous enquiries"
  type           = "ATHENA"
  parameters {
    athena {
      work_group = aws_athena_workgroup.analytics.name
      role_arn   = aws_iam_role.quicksight[0].arn
    }
  }
  permission {
    principal = aws_quicksight_user.admin[0].arn
    actions = ["quicksight:DescribeDataSource", "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource", "quicksight:UpdateDataSource", "quicksight:DeleteDataSource",
    "quicksight:UpdateDataSourcePermissions"]
  }
  depends_on = [aws_iam_role_policy.quicksight]
}
output "quicksight_invitation" {
  value     = local.quicksight_enabled ? aws_quicksight_user.admin[0].user_invitation_url : "Set quicksight_email to enable."
  sensitive = true
}
