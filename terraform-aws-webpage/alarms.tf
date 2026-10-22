locals {
  queue_alarms = { backlog = aws_sqs_queue.contacts.name, dead = aws_sqs_queue.dead.name,
  outbox = aws_sqs_queue.outbox.name }
}
resource "aws_cloudwatch_metric_alarm" "queue" {
  for_each            = local.queue_alarms
  alarm_name          = "moto-${each.key}"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = each.value }
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.key == "dead" ? 0 : 50
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.agents.arn]
}
resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "moto-api-errors"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  dimensions          = { ApiName = aws_api_gateway_rest_api.contacts.name, Stage = "prod" }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 5
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.agents.arn]
}
