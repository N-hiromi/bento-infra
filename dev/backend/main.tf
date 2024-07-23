################# data #################
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.project_key]
  }
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-public*"]
  }
}

data "aws_security_group" "alb" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-alb-sg"]
  }
}

data "aws_security_group" "app" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-app-sg"]
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

################# iam #################
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.project_key}-ecs-task-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

################# ecs #################
module "ecs" {
  source             = "terraform-aws-modules/ecs/aws"
  name               = "${local.project_key}-cluster"
  container_insights = true
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}

module "log_group" {
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  name              = "/ecs/${local.project_key}-app"
  retention_in_days = 120
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.project_key}-app-family"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name = "${local.project_key}-app"
      //      image     = "httpd"
      image     = "078603973787.dkr.ecr.ap-northeast-1.amazonaws.com/${local.project_key}-app:latest"
      essential = true
      logConfiguration : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/${local.project_key}-app",
          "awslogs-region" : "ap-northeast-1",
          "awslogs-stream-prefix" : "ecs"
        }
      },
      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
      }]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${local.project_key}-app"
  depends_on      = [module.alb]
  launch_type     = "FARGATE"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  network_configuration {
    subnets          = data.aws_subnet_ids.public_subnet_ids.ids
    security_groups  = [data.aws_security_group.app.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns[0]
    container_name   = "${local.project_key}-app"
    container_port   = 8080
  }
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = "${local.project_key}-alb"
  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.vpc.id
  subnets         = data.aws_subnet_ids.public_subnet_ids.ids
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

  http_tcp_listeners = [{
    port               = 80
    protocol           = "HTTP"
    target_group_index = 0
  }]
}
