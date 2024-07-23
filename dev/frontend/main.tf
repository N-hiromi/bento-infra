################# s3 #################
module "front-s3" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket        = "${local.project_key}-front"
  acl           = "private"
  attach_policy = true
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "PolicyForCloudFrontPrivateContent",
    "Statement" : [
      {
        Sid : "1",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${module.cdn.cloudfront_origin_access_identity_ids[0]}"
        },
        Action : "s3:GetObject",
        Resource : "arn:aws:s3:::${local.project_key}-front/*"
      }
    ]
  })
}

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

################# cloud-front #################
data "aws_cloudfront_cache_policy" "s3" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "alb" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "alb" {
  name = "Managed-AllViewer"
}

data "aws_lb" "app" {
  name = "${local.project_key}-alb"
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"
  //  aliases = ["cdn.example.com"]
  comment             = "${local.project_key}-front"
  enabled             = true
  is_ipv6_enabled     = false
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.this.arn

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "${local.project_key}-identity"
  }

  logging_config = {
    bucket = "${local.project_key}-log.s3.amazonaws.com"
  }

  origin = {
    s3_origin = {
      domain_name = module.front-s3.s3_bucket_bucket_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
    alb_origin = {
      domain_name = data.aws_lb.app.dns_name
      custom_origin_config = {
        origin_protocol_policy   = "http-only"
        origin_ssl_protocols     = ["TLSv1"]
        origin_keepalive_timeout = 5
        http_port                = 80
        https_port               = 443
      }
      custom_header = {
        value = {
          name  = "cloudfront-custom-header"
          value = "${local.project_key}-value"
        }
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = false
    cache_policy_id = data.aws_cloudfront_cache_policy.s3.id
    //    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.s3.id
    use_forwarded_values = false
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "alb_origin"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = false
      query_string             = true
      cache_policy_id          = data.aws_cloudfront_cache_policy.alb.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.alb.id
      use_forwarded_values     = false
    }
  ]

  //  viewer_certificate = {
  //    acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
  //    ssl_support_method  = "sni-only"
  //  }
}

