variable "website_domain" {
  description = "Owned domain in the existing Route 53 zone; empty uses CloudFront's hostname."
  type        = string
  default     = "abubakir-dev.com"
  validation {
    condition     = var.website_domain == "" || can(regex("^[a-z0-9][a-z0-9.-]+\\.[a-z]{2,}$", var.website_domain))
    error_message = "Use a lowercase DNS hostname without a scheme or path, or an empty string."
  }
}

variable "dns_zone_name" {
  description = "Existing public Route 53 hosted zone containing website_domain."
  type        = string
  default     = "abubakir-dev.com"
}

locals {
  custom_domain = var.website_domain != ""
}

data "aws_route53_zone" "website" {
  count        = local.custom_domain ? 1 : 0
  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_acm_certificate" "website" {
  count             = local.custom_domain ? 1 : 0
  domain_name       = var.website_domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate" {
  for_each = local.custom_domain ? {
    for option in aws_acm_certificate.website[0].domain_validation_options : option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  } : {}
  zone_id = data.aws_route53_zone.website[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "website" {
  count                   = local.custom_domain ? 1 : 0
  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate : record.fqdn]
}

resource "aws_route53_record" "website" {
  for_each = local.custom_domain ? toset(["A", "AAAA"]) : toset([])
  zone_id  = data.aws_route53_zone.website[0].zone_id
  name     = var.website_domain
  type     = each.value
  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}
