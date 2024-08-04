module "alb" {
  version            = "~> 9.10.0"
  source             = "terraform-aws-modules/alb/aws"
  name               = "${local.project_key}-alb"
  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.vpc.id
  subnets         = data.aws_subnets.public_subnets.ids
  security_groups = [data.aws_security_group.alb.id]
  //  access_logs = {
  //    bucket = "${local.project_key}-log"
  //  }

  target_groups = {
    instance = {
      #      TODO "dev"がベタがきなので、変数化したい。6文字以内に抑えないといけない
      name_prefix      = "api"
      backend_protocol = "HTTPS"
      backend_port     = 443
      target_type      = "instance"
      target_id = aws_ecs_task_definition.api.id
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 8080
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port     = 443
      protocol = "HTTPS"
      #    TODO   証明書のarnを設定
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
    }
  }
}


resource "aws_lb_listener_rule" "allow_custom_header" {
  listener_arn = module.alb.listeners[0].arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = module.alb.target_groups[0].arn
  }

  condition {
    http_header {
      http_header_name = "Custom-Header"
      #       ランダムな文字列を設定
      values = ["1eWNx5XLlXeBmf70pEzk"]
    }
  }
}