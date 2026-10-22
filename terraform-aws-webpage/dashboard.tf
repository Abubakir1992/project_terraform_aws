resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "Motohaus-Operations"
  dashboard_body = jsonencode({ widgets = [
    { type = "metric", x = 0, y = 0, width = 12, height = 6, properties = {
      title = "Contact API traffic and server errors", region = "us-east-1", period = 300,
      stat = "Sum", metrics = [
        ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.contacts.name, "Stage", "prod"],
        ["AWS/ApiGateway", "5XXError", "ApiName", aws_api_gateway_rest_api.contacts.name, "Stage", "prod"]
      ]
    } },
    { type = "metric", x = 12, y = 0, width = 12, height = 6, properties = {
      title = "Lambda errors", region = "us-east-1", period = 300, stat = "Sum", metrics = [
        ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.personal.function_name],
        ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.worker.function_name]
      ]
    } },
    { type = "metric", x = 0, y = 6, width = 12, height = 6, properties = {
      title = "Queue backlog and dead letters", region = "us-east-1", period = 300,
      stat = "Maximum", metrics = [
        ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.contacts.name],
        ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.outbox.name],
        ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.dead.name]
      ]
    } },
    { type = "metric", x = 12, y = 6, width = 12, height = 6, properties = {
      title = "ALB healthy instances", region = "us-east-1", period = 60,
      stat = "Minimum", metrics = [
        ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.web.arn_suffix,
        "TargetGroup", aws_lb_target_group.web.arn_suffix]
      ]
    } }
  ] })
}
