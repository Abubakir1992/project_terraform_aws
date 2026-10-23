# Publish React after initial creation/recreation and after frontend/config changes.
# The machine running Terraform needs PowerShell 7, Node/npm and AWS CLI.
resource "terraform_data" "react_publish" {
  triggers_replace = {
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
    command     = "pwsh -NoProfile -NonInteractive -File scripts/deploy-react.ps1"
    environment = {
      MOTO_RELEASE_BUCKET      = aws_s3_bucket.releases.id
      MOTO_RELEASE_ASSOCIATION = aws_ssm_association.release.association_id
      MOTO_APP_CONFIG          = jsonencode(local.app_config)
    }
  }
  depends_on = [aws_autoscaling_group.web, aws_iam_role_policy.release]
}
