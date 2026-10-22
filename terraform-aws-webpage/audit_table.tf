resource "aws_glue_catalog_table" "audit" {
  name          = "cloudtrail"
  database_name = aws_glue_catalog_database.analytics.name
  table_type    = "EXTERNAL_TABLE"
  parameters    = { EXTERNAL = "TRUE", classification = "cloudtrail" }
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.audit.id}/AWSLogs/${local.suffix}/CloudTrail/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info { serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe" }
    columns {
      name = "eventtime"
      type = "string"
    }
    columns {
      name = "eventsource"
      type = "string"
    }
    columns {
      name = "eventname"
      type = "string"
    }
    columns {
      name = "awsregion"
      type = "string"
    }
    columns {
      name = "errorcode"
      type = "string"
    }
  }
}
resource "aws_athena_named_query" "audit" {
  name      = "AWS API activity and errors"
  workgroup = aws_athena_workgroup.analytics.id
  database  = aws_glue_catalog_database.analytics.name
  query     = "SELECT eventsource,eventname,errorcode,count(*) AS events FROM cloudtrail GROUP BY 1,2,3 ORDER BY events DESC LIMIT 100"
}
