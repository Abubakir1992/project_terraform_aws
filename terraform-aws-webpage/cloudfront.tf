data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}
resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  web_acl_id          = aws_wafv2_web_acl.protection["edge"].arn
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
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  origin {
    domain_name = "${aws_api_gateway_rest_api.contacts.id}.execute-api.us-east-1.amazonaws.com"
    origin_id   = "contact-api"
    origin_path = "/prod"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "contact-api"
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.api.id
  }
  default_cache_behavior {
    target_origin_id       = "webpage-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id
    compress               = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
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
