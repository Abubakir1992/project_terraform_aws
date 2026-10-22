resource "aws_ssm_document" "telemetry" {
  name          = "moto-configure-logs"
  document_type = "Command"
  content = jsonencode({ schemaVersion = "2.2", mainSteps = [{
    action = "aws:runShellScript", name = "cloudwatch", inputs = { runCommand = [
      "set -eu",
      "cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'\n${file("${path.module}/scripts/cloudwatch.json")}\nJSON",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
    ] }
  }] })
}
resource "aws_ssm_association" "telemetry" {
  name                = aws_ssm_document.telemetry.name
  document_version    = "$LATEST"
  schedule_expression = "rate(30 minutes)"
  targets {
    key    = "tag:Application"
    values = ["moto"]
  }
  depends_on = [aws_iam_role_policy_attachment.ssm, aws_cloudwatch_log_group.web]
}
