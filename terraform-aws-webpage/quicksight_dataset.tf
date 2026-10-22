resource "aws_quicksight_data_set" "contacts" {
  count       = local.quicksight_enabled ? 1 : 0
  data_set_id = "moto-daily-enquiries"
  name        = "Daily motorcycle enquiries"
  import_mode = "DIRECT_QUERY"
  physical_table_map {
    physical_table_map_id = "daily"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.athena[0].arn
      name            = "Daily anonymous totals"
      sql_query       = "SELECT event_date,interest,count(DISTINCT request_id) AS requests FROM moto_analytics.contacts GROUP BY 1,2"
      columns {
        name = "event_date"
        type = "STRING"
      }
      columns {
        name = "interest"
        type = "STRING"
      }
      columns {
        name = "requests"
        type = "INTEGER"
      }
    }
  }
  permissions {
    principal = aws_quicksight_user.admin[0].arn
    actions = ["quicksight:DescribeDataSet", "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet", "quicksight:DescribeIngestion", "quicksight:ListIngestions",
      "quicksight:UpdateDataSet", "quicksight:DeleteDataSet", "quicksight:CreateIngestion",
    "quicksight:CancelIngestion", "quicksight:UpdateDataSetPermissions"]
  }
  depends_on = [aws_glue_catalog_table.contacts]
}
