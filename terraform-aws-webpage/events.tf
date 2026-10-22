resource "aws_cloudwatch_event_bus" "contacts" { name = "moto-contacts" }
resource "aws_cloudwatch_event_rule" "contacts" {
  name           = "contact-created"
  event_bus_name = aws_cloudwatch_event_bus.contacts.name
  event_pattern  = jsonencode({ source = ["moto.contacts"], "detail-type" = ["ContactCreated"] })
}
resource "aws_sqs_queue" "dead" {
  name                      = "moto-contacts-dead"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
}
resource "aws_sqs_queue" "contacts" {
  name                       = "moto-contacts"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 180
  message_retention_seconds  = 1209600
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dead.arn, maxReceiveCount = 5 })
}
resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.contacts.url
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Principal = { Service = "events.amazonaws.com" },
    Action    = "sqs:SendMessage", Resource = aws_sqs_queue.contacts.arn,
    Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.contacts.arn } }
  }] })
}
resource "aws_cloudwatch_event_target" "contacts" {
  rule           = aws_cloudwatch_event_rule.contacts.name
  event_bus_name = aws_cloudwatch_event_bus.contacts.name
  arn            = aws_sqs_queue.contacts.arn
  dead_letter_config { arn = aws_sqs_queue.dead.arn }
  retry_policy { maximum_event_age_in_seconds = 86400 }
  depends_on = [aws_sqs_queue_policy.events, aws_sqs_queue_policy.event_dead]
}
resource "aws_sns_topic" "agents" { name = "moto-agent-notifications" }
resource "aws_sns_topic_subscription" "agents" {
  count     = var.notification_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.agents.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
