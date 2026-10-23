# This development project supports complete destroy/recreate cycles.
resource "aws_quicksight_account_settings" "moto" {
  count                          = local.quicksight_enabled && var.create_quicksight_subscription ? 1 : 0
  aws_account_id                 = local.suffix
  default_namespace              = "default"
  termination_protection_enabled = false
  depends_on                     = [aws_quicksight_account_subscription.moto]
}
