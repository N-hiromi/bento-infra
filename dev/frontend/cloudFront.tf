resource "aws_cloudfront_distribution" "alb_distribution" {
  origin {
    domain_name = data.aws_lb.app.dns_name
    origin_id   = data.aws_lb.app.id
#     ランダムな文字列を設定。Custom-HeaderをcloudFrontで付与してalbに送る。albはこの文字列をチェックする。
    custom_header {
      name  = "Custom-Header"
      value = "1eWNx5XLlXeBmf70pEzk"
    }

    custom_origin_config {
      http_port              = 8080
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
    cached_methods   = ["GET", "HEAD"]
    target_origin_id       = data.aws_lb.app.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  web_acl_id      = aws_wafv2_web_acl.this.arn
  enabled         = true
  is_ipv6_enabled = true

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = local.project_key
  }
}
