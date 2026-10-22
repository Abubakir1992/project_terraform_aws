resource "aws_sqs_queue_policy" "event_dead" {
  queue_url = aws_sqs_queue.dead.url
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Principal = { Service = "events.amazonaws.com" },
    Action    = "sqs:SendMessage", Resource = aws_sqs_queue.dead.arn,
    Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.contacts.arn } }
  }] })
}
