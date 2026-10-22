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
      CLUSTER_ARN  = aws_rds_cluster.personal.arn
      SECRET_ARN   = aws_rds_cluster.personal.master_user_secret[0].secret_arn
      DATABASE     = aws_rds_cluster.personal.database_name
      CLIENT_ID    = aws_cognito_user_pool_client.personal.id
      OUTBOX_QUEUE = aws_sqs_queue.outbox.url
    }
  }
  depends_on = [aws_iam_role_policy.personal, aws_rds_cluster_instance.personal]
}
