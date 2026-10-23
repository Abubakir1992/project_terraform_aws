resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
resource "aws_iam_role" "github_deploy" {
  name = "moto-github-deploy"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
    Action = "sts:AssumeRoleWithWebIdentity", Condition = { StringEquals = {
      "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub" = "repo:Abubakir1992@79552141/project_terraform_aws@1408548768:environment:production"
    } }
  }] })
}
resource "aws_iam_role_policy" "github_deploy" {
  role = aws_iam_role.github_deploy.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["s3:ListBucket", "s3:GetBucketLocation"], Resource = "arn:aws:s3:::abubakir-terraform-state-e1ac9875972c93c0548685fa0d" },
    { Effect = "Allow", Action = ["s3:GetObject"], Resource = "arn:aws:s3:::abubakir-terraform-state-e1ac9875972c93c0548685fa0d/webpage/terraform.tfstate" },
    { Effect = "Allow", Action = ["s3:ListBucket", "s3:GetBucketLocation"], Resource = aws_s3_bucket.releases.arn },
    { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject"], Resource = "${aws_s3_bucket.releases.arn}/site/*" },
    { Effect = "Allow", Action = ["s3:PutObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.releases.arn}/artifacts/github-actions/*" },
    { Effect = "Allow", Action = ["ssm:StartAssociationsOnce"], Resource = "arn:aws:ssm:us-east-1:${local.suffix}:association/${aws_ssm_association.release.association_id}" }
  ] })
}
output "github_deploy_role" { value = aws_iam_role.github_deploy.arn }
