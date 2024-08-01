module "alb" {
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
