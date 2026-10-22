resource "aws_glue_catalog_database" "analytics" { name = "moto_analytics" }
resource "aws_athena_workgroup" "analytics" {
  name          = "moto-analytics"
  force_destroy = true
  configuration {
    enforce_workgroup_configuration    = true
    bytes_scanned_cutoff_per_query     = 1073741824
    publish_cloudwatch_metrics_enabled = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.id}/queries/"
      encryption_configuration { encryption_option = "SSE_S3" }
    }
  }
}
resource "aws_glue_catalog_table" "contacts" {
  name          = "contacts"
  database_name = aws_glue_catalog_database.analytics.name
  table_type    = "EXTERNAL_TABLE"
  parameters    = { EXTERNAL = "TRUE", classification = "json" }
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.analytics.id}/contacts/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info { serialization_library = "org.openx.data.jsonserde.JsonSerDe" }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "event_date"
      type = "string"
    }
    columns {
      name = "interest"
      type = "string"
    }
    columns {
      name = "requests"
      type = "int"
    }
  }
}
resource "aws_athena_named_query" "daily" {
  name      = "Daily motorcycle enquiries"
  workgroup = aws_athena_workgroup.analytics.id
  database  = aws_glue_catalog_database.analytics.name
  query     = "SELECT event_date, interest, count(DISTINCT request_id) AS requests FROM contacts GROUP BY 1,2 ORDER BY 1 DESC"
}
output "athena_workgroup" { value = aws_athena_workgroup.analytics.name }
