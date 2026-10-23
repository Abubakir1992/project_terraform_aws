locals { waf_scopes = { edge = "CLOUDFRONT", api = "REGIONAL" } }
resource "aws_wafv2_web_acl" "protection" {
  for_each = local.waf_scopes
  name     = "moto-${each.key}"
  scope    = each.value
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "moto-${each.key}"
    sampled_requests_enabled   = false
  }
  rule {
    name     = "us-only"
    priority = 0
    override_action {
      none {}
    }
    statement {
      rule_group_reference_statement { arn = aws_wafv2_rule_group.us_only[each.key].arn }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "us-only-${each.key}"
      sampled_requests_enabled   = false
    }
  }
  rule {
    name     = "common-threats"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-threats-${each.key}"
      sampled_requests_enabled   = false
    }
  }
  rule {
    name     = "rate-limit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-${each.key}"
      sampled_requests_enabled   = false
    }
  }
}
