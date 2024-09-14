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