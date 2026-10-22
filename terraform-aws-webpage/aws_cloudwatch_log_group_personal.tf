resource "aws_cloudwatch_log_group" "personal" {
  name              = "/aws/lambda/webpage-personal-api"
  retention_in_days = 14
}
