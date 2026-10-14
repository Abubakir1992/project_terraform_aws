# AWS supplies a trusted HTTPS hostname and certificate without a custom domain.
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  comment             = "HTTPS website for the personal-data React app"
  aliases             = local.custom_domain ? [var.website_domain] : []
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2"
  wait_for_deployment = true

  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = "webpage-alb"
    # Only static assets/config travel through this origin. Personal data and
    # auth tokens go directly to API Gateway/Cognito HTTPS endpoints.
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "webpage-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id
    compress               = true
    # No origin request policy: OAuth query strings/cookies stay at the browser.
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.custom_domain
    acm_certificate_arn            = local.custom_domain ? aws_acm_certificate_validation.website[0].certificate_arn : null
    ssl_support_method             = local.custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.custom_domain ? "TLSv1.2_2021" : "TLSv1"
  }

  depends_on = [aws_lb_listener.http]
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.web.id
}
