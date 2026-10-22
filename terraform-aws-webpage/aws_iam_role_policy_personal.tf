resource "aws_iam_role_policy" "personal" {
  role = aws_iam_role.personal.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["sqs:SendMessage"], Resource = aws_sqs_queue.outbox.arn },
      { Effect = "Allow", Action = ["rds-data:ExecuteStatement"], Resource = aws_rds_cluster.personal.arn },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = aws_rds_cluster.personal.master_user_secret[0].secret_arn },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.personal.arn}:*" }
    ]
  })
}
