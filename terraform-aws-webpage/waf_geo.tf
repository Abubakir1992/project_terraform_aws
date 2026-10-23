resource "aws_wafv2_rule_group" "us_only" {
  for_each = local.waf_scopes
  name     = "moto-us-only-${each.key}"
  scope    = each.value
  capacity = 1
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "moto-us-only-${each.key}"
    sampled_requests_enabled   = false
  }
  rule {
    name     = "block-outside-us"
    priority = 0
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          geo_match_statement { country_codes = ["US"] }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "outside-us-${each.key}"
      sampled_requests_enabled   = false
    }
  }
}
