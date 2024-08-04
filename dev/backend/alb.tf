# module "alb" {
#   version            = "~> 9.10.0"
#   source             = "terraform-aws-modules/alb/aws"
#   name               = "${local.project_key}-alb"
#   load_balancer_type = "application"
#
#   // TODO 後で消す
#   enable_deletion_protection = false
#   vpc_id          = data.aws_vpc.vpc.id
#   subnets         = data.aws_subnets.public_subnets.ids
#   security_groups = [data.aws_security_group.alb.id]
#   //  access_logs = {
#   //    bucket = "${local.project_key}-log"
#   //  }
#
#   target_groups = {
#     ex-ecs = {
#       name_prefix      = "api"
#       backend_protocol = "HTTP"
#       backend_port     = 8080
#       target_type      = "ip"
#       target_id        = aws_ecs_service.api.
#     }
#   }
#
#   listeners = {
#     ex-http = {
#       port     = 8080
#       protocol = "HTTP"
#       forward = {
#         target_group_key = "ex-ecs"
#       }
#     }
#   }
# }
#
#
# resource "aws_lb_listener_rule" "allow_custom_header" {
#   listener_arn = module.alb.listeners["ex-http"].arn
#   priority     = 100
#   action {
#     type             = "forward"
#     target_group_arn = module.alb.target_groups["ex-ecs"].arn
#   }
#
#   condition {
#     http_header {
#       http_header_name = "Custom-Header"
#       #       ランダムな文字列を設定
#       values = ["1eWNx5XLlXeBmf70pEzk"]
#     }
#   }
# }

// 上記moduleのエラー解決ができなかったからresourceに置き換えた
resource "aws_lb" "alb" {
  name               = "${local.project_key}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public_subnets.ids
  // TODO 後でtrueにすること
  enable_deletion_protection = false
  //  access_logs = {
  //    bucket = "${local.project_key}-log"
  //  }
}

resource "aws_lb_target_group" "fargate_target_group" {
  name        = "${local.project_key}-lb-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_target_group.arn
  }
}

resource "aws_lb_listener_rule" "allow_custom_header" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_target_group.arn
  }

  condition {
    http_header {
      http_header_name = "Custom-Header"
      #       ランダムな文字列を設定
      values = ["1eWNx5XLlXeBmf70pEzk"]
    }
  }
}