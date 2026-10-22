resource "aws_cognito_user" "administrator" {
  count                    = var.administrator_username != "" ? 1 : 0
  user_pool_id             = aws_cognito_user_pool.personal.id
  username                 = var.administrator_username
  attributes               = { email = var.administrator_username }
  desired_delivery_mediums = ["EMAIL"]
}
