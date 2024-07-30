resource "aws_cloudfront_distribution" "alb_distribution" {
  origin {
    domain_name = data.aws_lb.app.dns_name
    origin_id   = data.aws_lb.app.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["IR", "KP", "CU", "SY", "SD", "VE"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = []
    target_origin_id       = data.aws_lb.app.id
    viewer_protocol_policy = "https-only"
  }

  web_acl_id      = aws_wafv2_web_acl.this.arn
  enabled         = true
  is_ipv6_enabled = true

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
