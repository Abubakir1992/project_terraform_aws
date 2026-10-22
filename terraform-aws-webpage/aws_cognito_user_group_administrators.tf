resource "aws_cognito_user_group" "administrators" {
  name         = "administrators"
  user_pool_id = aws_cognito_user_pool.personal.id
  description  = "May view the personal-data records of all invited users"
}
