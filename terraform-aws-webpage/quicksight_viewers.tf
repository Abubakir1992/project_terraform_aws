variable "quicksight_dashboard_viewer_arns" {
  type        = set(string)
  default     = []
  description = "Existing QuickSight user ARNs allowed to view the aggregate dashboard."
}
