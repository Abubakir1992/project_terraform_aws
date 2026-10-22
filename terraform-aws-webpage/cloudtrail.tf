resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
      Action = "s3:GetBucketAcl", Resource = aws_s3_bucket.audit.arn,
    Condition = { StringEquals = { "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:${local.suffix}:trail/moto-audit" } } },
    { Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
      Action = "s3:PutObject", Resource = "${aws_s3_bucket.audit.arn}/AWSLogs/${local.suffix}/*",
      Condition = { StringEquals = {
        "s3:x-amz-acl"  = "bucket-owner-full-control",
        "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:${local.suffix}:trail/moto-audit"
    } } },
    { Effect   = "Deny", Principal = "*", Action = "s3:*",
      Resource = [aws_s3_bucket.audit.arn, "${aws_s3_bucket.audit.arn}/*"],
    Condition = { Bool = { "aws:SecureTransport" = "false" } } }
  ] })
}
resource "aws_cloudtrail" "audit" {
  name                          = "moto-audit"
  s3_bucket_name                = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  depends_on = [aws_s3_bucket_policy.audit]
}
output "audit_bucket" { value = aws_s3_bucket.audit.id }
