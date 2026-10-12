terraform {
  backend "s3" {
    bucket       = "abubakir-terraform-state-e1ac9875972c93c0548685fa0d"
    key          = "project_terraform_aws/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}