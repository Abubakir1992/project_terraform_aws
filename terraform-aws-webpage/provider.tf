terraform {
  required_version = ">= 1.10.0"
  required_providers {
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
provider "aws" { region = "us-east-1" }
data "aws_caller_identity" "current" {}
locals { suffix = data.aws_caller_identity.current.account_id }
