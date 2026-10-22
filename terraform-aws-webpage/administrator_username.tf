variable "administrator_username" {
  description = "Existing Cognito username to grant administrator listing access; configure privately in local tfvars."
  type        = string
  default     = ""
}
