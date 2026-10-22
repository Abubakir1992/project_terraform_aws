resource "aws_sqs_queue" "outbox" {
  name                       = "moto-outbox"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 180
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dead.arn, maxReceiveCount = 5 })
}
resource "aws_lambda_event_source_mapping" "outbox" {
  event_source_arn        = aws_sqs_queue.outbox.arn
  function_name           = aws_lambda_function.worker.arn
  function_response_types = ["ReportBatchItemFailures"]
  batch_size              = 10
  depends_on              = [aws_iam_role_policy.worker]
}
