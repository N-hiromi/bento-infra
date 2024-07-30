################# iam #################
resource "aws_iam_role" "ecs_task_role_api" {
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
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
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
  name              = "/ecs/${local.project_key}-api"
  retention_in_days = 120
}

resource "aws_ecs_service" "api" {
  name            = "${local.project_key}-api"
  depends_on      = [module.alb]
  launch_type     = "FARGATE"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2

  network_configuration {
    subnets          = data.aws_subnet_ids.public_subnet_ids.ids
    security_groups  = [data.aws_security_group.api.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.alb.target_groups[0].arn
    container_name   = "${local.project_key}-api"
    container_port   = 8080
  }
}


resource "aws_ecs_task_definition" "api" {
  family                   = "${local.project_key}-api-family"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role_api.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name = "${local.project_key}-api"
      //      image     = "httpd"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true
      logConfiguration : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/${local.project_key}-api",
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