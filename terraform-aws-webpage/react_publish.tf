# Publish React after initial creation/recreation and after frontend/config changes.
# Uses built-in Windows PowerShell; Node/npm and AWS CLI must be installed.
resource "terraform_data" "react_publish" {
  triggers_replace = {
    runner      = "windows-powershell-5.1"
    association = aws_ssm_association.release.association_id
    config      = sha256(jsonencode(local.app_config))
    frontend = sha256(join("", [for name in sort(tolist(fileset("${path.module}/../react-app", "**"))) :
      filesha256("${path.module}/../react-app/${name}")
      if !can(regex("(^|/)(node_modules|dist)(/|$)", name))
    ]))
    publisher = filesha256("${path.module}/../scripts/deploy-react.ps1")
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/.."
    interpreter = ["C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
    "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"]
    command = "scripts/deploy-react.ps1"
    environment = {
      MOTO_RELEASE_BUCKET      = aws_s3_bucket.releases.id
      MOTO_RELEASE_ASSOCIATION = aws_ssm_association.release.association_id
      MOTO_APP_CONFIG          = jsonencode(local.app_config)
    }
  }
  depends_on = [aws_autoscaling_group.web, aws_iam_role_policy.release]
}
