resource "aws_cognito_user_pool_client" "personal" {
  name                                 = "webpage-react"
  user_pool_id                         = aws_cognito_user_pool.personal.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["${local.website_origin}/admin.html"]
  logout_urls                          = ["${local.website_origin}/admin.html"]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  access_token_validity                = 15
  id_token_validity                    = 15
  token_validity_units {
    access_token = "minutes"
    id_token     = "minutes"
  }
}
