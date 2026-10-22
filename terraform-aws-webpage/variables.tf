# Prefer AWS_PROFILE / AWS CLI credentials. Never commit access keys.
variable "aws_access_key" {
  type      = string
  default   = ""
  sensitive = true
}
variable "aws_secret_key" {
  type      = string
  default   = ""
  sensitive = true
}
variable "notification_email" {
  description = "Optional SNS subscriber; confirm the AWS email after apply. No personal data is sent."
  type        = string
  default     = ""
}
