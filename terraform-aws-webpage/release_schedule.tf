resource "aws_iam_role" "release_schedule" {
  name_prefix = "moto-release-schedule-"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "scheduler.amazonaws.com" },
    Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = local.suffix } }
  }] })
}
resource "aws_iam_role_policy" "release_schedule" {
  role = aws_iam_role.release_schedule.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect   = "Allow", Action = ["ssm:StartAssociationsOnce"],
    Resource = "arn:aws:ssm:us-east-1:${local.suffix}:association/${aws_ssm_association.release.association_id}"
  }] })
}
resource "aws_scheduler_schedule" "release" {
  name                = "moto-react-reconciliation"
  schedule_expression = "rate(5 minutes)"
  flexible_time_window { mode = "OFF" }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ssm:startAssociationsOnce"
    role_arn = aws_iam_role.release_schedule.arn
    input    = jsonencode({ AssociationIds = [aws_ssm_association.release.association_id] })
    retry_policy {
      maximum_event_age_in_seconds = 300
      maximum_retry_attempts       = 2
    }
  }
  depends_on = [aws_iam_role_policy.release_schedule]
}
