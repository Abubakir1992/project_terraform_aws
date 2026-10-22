resource "aws_cognito_user_pool_domain" "personal" {
  domain       = "webpage-${lower(replace(aws_cognito_user_pool.personal.id, "_", "-"))}"
  user_pool_id = aws_cognito_user_pool.personal.id
}
