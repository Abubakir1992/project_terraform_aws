resource "aws_s3_bucket" "state" {
  bucket_prefix = "abubakir-terraform-state-"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "Terraform State"
    Project = "project_terraform_aws"
  }
}
