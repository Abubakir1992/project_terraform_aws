data "archive_file" "worker" {
  type        = "zip"
  source_file = "${path.module}/../event-worker/handler.py"
  output_path = "${path.module}/event-worker.zip"
}
resource "aws_lambda_function" "worker" {
  function_name    = "moto-events"
  role             = aws_iam_role.worker.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.worker.output_path
  source_code_hash = data.archive_file.worker.output_base64sha256
  timeout          = 30
  environment {
    variables = {
      TOPIC_ARN        = aws_sns_topic.agents.arn
      ANALYTICS_BUCKET = aws_s3_bucket.analytics.id
      BUS_NAME         = aws_cloudwatch_event_bus.contacts.name
      OUTBOX_ARN       = aws_sqs_queue.outbox.arn
    }
  }
  depends_on = [aws_iam_role_policy.worker]
}
resource "aws_lambda_event_source_mapping" "contacts" {
  event_source_arn        = aws_sqs_queue.contacts.arn
  function_name           = aws_lambda_function.worker.arn
  function_response_types = ["ReportBatchItemFailures"]
  batch_size              = 10
  depends_on              = [aws_iam_role_policy.worker]
}
resource "aws_cloudwatch_log_group" "worker" {
  name              = "/aws/lambda/moto-events"
  retention_in_days = 14
}
resource "aws_iam_role" "worker" {
  name_prefix = "moto-events-"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole"
  }] })
}
resource "aws_iam_role_policy" "worker" {
  role = aws_iam_role.worker.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = [aws_sqs_queue.contacts.arn, aws_sqs_queue.outbox.arn] },
    { Effect = "Allow", Action = ["events:PutEvents"], Resource = aws_cloudwatch_event_bus.contacts.arn },
    { Effect = "Allow", Action = ["sns:Publish"], Resource = aws_sns_topic.agents.arn },
    { Effect = "Allow", Action = ["s3:PutObject"], Resource = "${aws_s3_bucket.analytics.arn}/contacts/*" },
    { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.worker.arn}:*" }
  ] })
}
