resource "aws_iam_role" "web" {
  name_prefix = "webpage-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "web" {
  name_prefix = "webpage-ec2-"
  role        = aws_iam_role.web.name

  depends_on = [aws_iam_role_policy_attachment.cloudwatch]
}

resource "aws_cloudwatch_log_group" "web" {
  for_each = toset([
    "/terraform-webpage/apache-access",
    "/terraform-webpage/apache-error",
    "/terraform-webpage/startup"
  ])

  name              = each.value
  retention_in_days = 14
}