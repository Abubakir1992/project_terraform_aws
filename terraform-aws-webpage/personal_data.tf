locals {
  website_origin = "https://${local.custom_domain ? var.website_domain : aws_cloudfront_distribution.web.domain_name}"
  app_config = {
    apiUrl      = "/api"
    authUrl     = "https://${aws_cognito_user_pool_domain.personal.domain}.auth.us-east-1.amazoncognito.com"
    clientId    = aws_cognito_user_pool_client.personal.id
    redirectUri = "${local.website_origin}/admin.html"
  }
}
output "app_config" { value = local.app_config }
