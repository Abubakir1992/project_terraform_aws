resource "aws_s3_bucket" "releases" {
  bucket        = "moto-releases-${local.suffix}"
  force_destroy = true
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy" "release" {
  role = aws_iam_role.web.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["s3:ListBucket"], Resource = aws_s3_bucket.releases.arn },
    { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.releases.arn}/site/*" }
  ] })
}
resource "aws_ssm_document" "release" {
  name          = "moto-deploy-react"
  document_type = "Command"
  content = jsonencode({ schemaVersion = "2.2", mainSteps = [{
    action = "aws:runShellScript", name = "deploy", inputs = {
      runCommand = split("\n", replace(templatefile("${path.module}/scripts/deploy.sh", {
        bucket = aws_s3_bucket.releases.id
      }), "\r", ""))
    }
  }] })
}
resource "aws_ssm_association" "release" {
  name                = aws_ssm_document.release.name
  association_name    = "moto-react-release"
  document_version    = "$LATEST"
  schedule_expression = "rate(30 minutes)"
  targets {
    key    = "tag:Application"
    values = ["moto"]
  }
  depends_on = [aws_iam_role_policy_attachment.ssm]
}
output "release_bucket" { value = aws_s3_bucket.releases.id }
output "release_association" { value = aws_ssm_association.release.association_id }
