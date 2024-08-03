module "alb" {
  version = "9.10.0"
  source             = "terraform-aws-modules/alb/aws"
  name               = "${local.project_key}-alb"
  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.vpc.id
  subnets         = data.aws_subnets.public_subnets.ids
  security_groups = [data.aws_security_group.alb.id]
  //  access_logs = {
  //    bucket = "${local.project_key}-log"
  //  }

  target_groups = [
    {
      name             = "${local.project_key}-app-targetgroup"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      targets = [
      ]
    }
  ]

  listeners = [{
    port               = 80
    protocol           = "HTTP"
    target_group_index = 0
  }]
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
      values           = ["1eWNx5XLlXeBmf70pEzk"]
    }
  }
}