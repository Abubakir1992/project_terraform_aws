variable "aurora_engine_version" {
  description = "Supported Aurora MySQL 3.x version with Data API and Serverless v2 in us-east-1."
  type        = string
  default     = "8.0.mysql_aurora.3.10.3"
}

locals {
  website_origin = "https://${aws_cloudfront_distribution.web.domain_name}"
  app_config = {
    apiUrl      = aws_apigatewayv2_api.personal.api_endpoint
    authUrl     = "https://${aws_cognito_user_pool_domain.personal.domain}.auth.us-east-1.amazoncognito.com"
    clientId    = aws_cognito_user_pool_client.personal.id
    redirectUri = "${local.website_origin}/"
  }
}

# Isolated subnets have no route to the internet; SQL is accessed through Data API.
resource "aws_subnet" "database" {
  for_each = {
    a = { cidr = "10.0.11.0/24", az = "us-east-1a" }
    b = { cidr = "10.0.12.0/24", az = "us-east-1b" }
  }
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "web-database-${each.key}" }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.web_vpc.id
}

resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}

resource "aws_db_subnet_group" "personal" {
  name_prefix = "webpage-personal-"
  subnet_ids  = [for subnet in aws_subnet.database : subnet.id]
}

resource "aws_security_group" "database" {
  name_prefix = "webpage-database-"
  description = "No inbound SQL connections; use authenticated RDS Data API"
  vpc_id      = aws_vpc.web_vpc.id
}

resource "aws_rds_cluster" "personal" {
  cluster_identifier_prefix   = "webpage-personal-"
  engine                      = "aurora-mysql"
  engine_mode                 = "provisioned"
  engine_version              = var.aurora_engine_version
  database_name               = "personal_data"
  master_username             = "app_admin"
  manage_master_user_password = true
  enable_http_endpoint        = true
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.personal.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  backup_retention_period     = 7
  deletion_protection         = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "webpage-personal-final"
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}

resource "aws_rds_cluster_instance" "personal" {
  identifier_prefix   = "webpage-personal-"
  cluster_identifier  = aws_rds_cluster.personal.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.personal.engine
  engine_version      = aws_rds_cluster.personal.engine_version
  publicly_accessible = false
}

resource "aws_cognito_user_pool" "personal" {
  name                     = "webpage-personal"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}

resource "aws_cognito_user_pool_client" "personal" {
  name                                 = "webpage-react"
  user_pool_id                         = aws_cognito_user_pool.personal.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["${local.website_origin}/"]
  logout_urls                          = ["${local.website_origin}/"]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  access_token_validity                = 15
  token_validity_units {
    access_token = "minutes"
  }
}

resource "aws_cognito_user_pool_domain" "personal" {
  domain       = "webpage-${lower(replace(aws_cognito_user_pool.personal.id, "_", "-"))}"
  user_pool_id = aws_cognito_user_pool.personal.id
}

data "archive_file" "personal" {
  type        = "zip"
  source_file = "${path.module}/../personal-api/handler.py"
  output_path = "${path.module}/personal-api.zip"
}

resource "aws_iam_role" "personal" {
  name_prefix = "webpage-personal-api-"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_cloudwatch_log_group" "personal" {
  name              = "/aws/lambda/webpage-personal-api"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "personal" {
  role = aws_iam_role.personal.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["rds-data:ExecuteStatement"], Resource = aws_rds_cluster.personal.arn },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = aws_rds_cluster.personal.master_user_secret[0].secret_arn },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.personal.arn}:*" }
    ]
  })
}

resource "aws_lambda_function" "personal" {
  function_name                  = "webpage-personal-api"
  role                           = aws_iam_role.personal.arn
  runtime                        = "python3.12"
  handler                        = "handler.handler"
  filename                       = data.archive_file.personal.output_path
  source_code_hash               = data.archive_file.personal.output_base64sha256
  timeout                        = 20
  reserved_concurrent_executions = 5
  environment {
    variables = {
      CLUSTER_ARN = aws_rds_cluster.personal.arn
      SECRET_ARN  = aws_rds_cluster.personal.master_user_secret[0].secret_arn
      DATABASE    = aws_rds_cluster.personal.database_name
    }
  }
  depends_on = [aws_iam_role_policy.personal, aws_rds_cluster_instance.personal]
}

resource "aws_apigatewayv2_api" "personal" {
  name          = "webpage-personal"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = [local.website_origin]
    allow_methods = ["PUT", "OPTIONS"]
    allow_headers = ["authorization", "content-type"]
  }
}

resource "aws_apigatewayv2_authorizer" "personal" {
  api_id           = aws_apigatewayv2_api.personal.id
  name             = "cognito"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.personal.id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.personal.id}"
  }
}

resource "aws_apigatewayv2_integration" "personal" {
  api_id                 = aws_apigatewayv2_api.personal.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.personal.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "personal" {
  api_id               = aws_apigatewayv2_api.personal.id
  route_key            = "PUT /personal-data"
  target               = "integrations/${aws_apigatewayv2_integration.personal.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.personal.id
  authorization_scopes = ["email"]
}

resource "aws_apigatewayv2_stage" "personal" {
  api_id      = aws_apigatewayv2_api.personal.id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

resource "aws_lambda_permission" "personal" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.personal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.personal.execution_arn}/*/PUT/personal-data"
}

output "personal_api_url" { value = aws_apigatewayv2_api.personal.api_endpoint }
output "cognito_user_pool_id" { value = aws_cognito_user_pool.personal.id }
output "aurora_cluster_arn" { value = aws_rds_cluster.personal.arn }
