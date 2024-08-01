data "aws_lb" "app" {
  name = "${local.project_key}-alb"
}