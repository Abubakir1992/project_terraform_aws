resource "aws_s3_bucket" "audit" {
  bucket        = "moto-cloudtrail-${local.suffix}"
  force_destroy = true
}
resource "aws_s3_bucket" "analytics" {
  bucket        = "moto-analytics-${local.suffix}"
  force_destroy = true
}
resource "aws_s3_bucket" "query_results" {
  bucket        = "moto-athena-results-${local.suffix}"
  force_destroy = true
}
locals {
  private_buckets = {
    releases  = aws_s3_bucket.releases.id, audit = aws_s3_bucket.audit.id,
    analytics = aws_s3_bucket.analytics.id, results = aws_s3_bucket.query_results.id
  }
}
resource "aws_s3_bucket_public_access_block" "private" {
  for_each                = local.private_buckets
  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  for_each = local.private_buckets
  bucket   = each.value
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}
resource "aws_s3_bucket_policy" "tls" {
  for_each = { for k, v in local.private_buckets : k => v if k != "audit" }
  bucket   = each.value
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Deny", Principal = "*", Action = "s3:*",
    Resource  = ["arn:aws:s3:::${each.value}", "arn:aws:s3:::${each.value}/*"],
    Condition = { Bool = { "aws:SecureTransport" = "false" } }
  }] })
}
resource "aws_s3_bucket_lifecycle_configuration" "results" {
  bucket = aws_s3_bucket.query_results.id
  rule {
    id     = "expire-results"
    status = "Enabled"
    filter {}
    expiration { days = 30 }
  }
}
