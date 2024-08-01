################# waf #################
resource "aws_wafv2_ip_set" "developers-ips" {
  provider           = aws.virginia
  name               = "developers_ipset"
  description        = "developers"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = [
    "3.115.183.88/32", // CXR-VPN
    //    "124.85.216.196/32" // 中村ビル-WIFI
    "118.7.19.222/32" // 小松自宅
  ]
}

resource "aws_wafv2_web_acl" "this" {
  provider    = aws.virginia
  name        = "${local.project_key}-acl"
  description = "${local.project_key}-acl"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "allow-ip"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.developers-ips.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.project_key}-allow-ip"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.project_key}-acl"
    sampled_requests_enabled   = false
  }
}
