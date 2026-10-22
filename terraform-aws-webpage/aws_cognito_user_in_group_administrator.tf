resource "aws_cognito_user_in_group" "administrator" {
  count        = var.administrator_username != "" ? 1 : 0
  user_pool_id = aws_cognito_user_pool.personal.id
  group_name   = aws_cognito_user_group.administrators.name
  username     = aws_cognito_user.administrator[0].username
}
