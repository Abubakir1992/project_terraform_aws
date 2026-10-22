resource "aws_api_gateway_rest_api" "contacts" {
  name = "moto-contacts"
  endpoint_configuration { types = ["REGIONAL"] }
}
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.contacts.id
  parent_id   = aws_api_gateway_rest_api.contacts.root_resource_id
  path_part   = "api"
}
resource "aws_api_gateway_resource" "routes" {
  for_each    = toset(["contact", "people"])
  rest_api_id = aws_api_gateway_rest_api.contacts.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = each.value
}
resource "aws_api_gateway_authorizer" "admin" {
  name          = "administrators"
  rest_api_id   = aws_api_gateway_rest_api.contacts.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.personal.arn]
}
resource "aws_api_gateway_method" "routes" {
  for_each      = { contact = "POST", people = "GET" }
  rest_api_id   = aws_api_gateway_rest_api.contacts.id
  resource_id   = aws_api_gateway_resource.routes[each.key].id
  http_method   = each.value
  authorization = each.key == "people" ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = each.key == "people" ? aws_api_gateway_authorizer.admin.id : null
}
resource "aws_api_gateway_integration" "routes" {
  for_each                = aws_api_gateway_method.routes
  rest_api_id             = aws_api_gateway_rest_api.contacts.id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.personal.invoke_arn
}
resource "aws_lambda_permission" "contacts" {
  statement_id  = "AllowContactsAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.personal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contacts.execution_arn}/prod/*/api/*"
}
