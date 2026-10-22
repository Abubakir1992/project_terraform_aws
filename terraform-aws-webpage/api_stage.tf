resource "aws_api_gateway_deployment" "contacts" {
  rest_api_id = aws_api_gateway_rest_api.contacts.id
  triggers = { redeployment = sha1(jsonencode([
    aws_api_gateway_resource.routes, aws_api_gateway_method.routes,
    aws_api_gateway_integration.routes, aws_api_gateway_authorizer.admin
  ])) }
  lifecycle { create_before_destroy = true }
}
resource "aws_api_gateway_stage" "contacts" {
  rest_api_id   = aws_api_gateway_rest_api.contacts.id
  deployment_id = aws_api_gateway_deployment.contacts.id
  stage_name    = "prod"
}
resource "aws_api_gateway_method_settings" "contacts" {
  rest_api_id = aws_api_gateway_rest_api.contacts.id
  stage_name  = aws_api_gateway_stage.contacts.stage_name
  method_path = "*/*"
  settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
    data_trace_enabled     = false
    logging_level          = "OFF"
  }
}
