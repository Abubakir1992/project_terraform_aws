resource "aws_iam_role" "quicksight" {
  count       = local.quicksight_enabled ? 1 : 0
  name_prefix = "moto-quicksight-"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Principal = { Service = "quicksight.amazonaws.com" }, Action = "sts:AssumeRole",
    Condition = { StringEquals = { "aws:SourceAccount" = local.suffix } }
  }] })
}
resource "aws_iam_role_policy" "quicksight" {
  count = local.quicksight_enabled ? 1 : 0
  role  = aws_iam_role.quicksight[0].id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["athena:StartQueryExecution", "athena:GetQueryExecution",
      "athena:GetQueryResults", "athena:StopQueryExecution", "athena:GetWorkGroup"],
    Resource = aws_athena_workgroup.analytics.arn },
    { Effect = "Allow", Action = ["athena:ListDataCatalogs", "athena:ListWorkGroups"], Resource = "*" },
    { Effect = "Allow", Action = ["athena:GetDataCatalog"], Resource = "arn:aws:athena:us-east-1:${local.suffix}:datacatalog/AwsDataCatalog" },
    { Effect = "Allow", Action = ["glue:GetDatabase", "glue:GetDatabases", "glue:GetTable",
      "glue:GetTables", "glue:GetPartitions"], Resource = [
      "arn:aws:glue:us-east-1:${local.suffix}:catalog",
    aws_glue_catalog_database.analytics.arn, aws_glue_catalog_table.contacts.arn] },
    { Effect = "Allow", Action = ["s3:GetBucketLocation", "s3:ListBucket"],
    Resource = [aws_s3_bucket.analytics.arn, aws_s3_bucket.query_results.arn] },
    { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.analytics.arn}/contacts/*" },
    { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"],
    Resource = "${aws_s3_bucket.query_results.arn}/queries/*" }
  ] })
}
