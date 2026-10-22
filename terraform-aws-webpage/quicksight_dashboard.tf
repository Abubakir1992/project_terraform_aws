resource "aws_quicksight_dashboard" "contacts" {
  count               = local.quicksight_enabled ? 1 : 0
  dashboard_id        = "moto-enquiries"
  name                = "Motohaus enquiry analytics"
  version_description = "Daily anonymous motorcycle enquiry totals"
  definition {
    data_set_identifiers_declarations {
      identifier   = "contacts"
      data_set_arn = aws_quicksight_data_set.contacts[0].arn
    }
    sheets {
      sheet_id = "daily"
      name     = "Daily enquiries by riding style"
      visuals {
        table_visual {
          visual_id = "daily-totals"
          chart_configuration {
            field_wells {
              table_unaggregated_field_wells {
                dynamic "values" {
                  for_each = ["event_date", "interest", "requests"]
                  content {
                    field_id = values.value
                    column {
                      column_name         = values.value
                      data_set_identifier = "contacts"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  permissions {
    principal = aws_quicksight_user.admin[0].arn
    actions = ["quicksight:DescribeDashboard", "quicksight:ListDashboardVersions",
      "quicksight:UpdateDashboardPermissions", "quicksight:QueryDashboard",
      "quicksight:UpdateDashboard", "quicksight:DeleteDashboard",
    "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPublishedVersion"]
  }
}
output "quicksight_dashboard" {
  value = local.quicksight_enabled ? "https://us-east-1.quicksight.aws.amazon.com/sn/dashboards/${aws_quicksight_dashboard.contacts[0].dashboard_id}" : "Disabled"
}
