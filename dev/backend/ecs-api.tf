################# iam #################
resource "aws_iam_role" "ecs_task_role_api" {
  name = "${local.project_key}-ecs-task-role-api"

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

# 共通設定
resource "aws_iam_role_policy_attachment" "cloudwatch_log_api" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_api" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr_api" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

# 固有の設定
resource "aws_iam_role_policy_attachment" "dynamodb_api" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "secret_manager_api" {
  role       = aws_iam_role.ecs_task_role_api.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

################# ecs #################
module "log_group_api" {
  version           = "5.4.0"
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  name              = "/ecs/${local.project_key}-api"
  retention_in_days = 120
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.project_key}-api-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role_api.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name = "${local.project_key}-api"
      //      image     = "httpd"
      image     = "${aws_ecr_repository.api.repository_url}:latest"

      # TODO デバッグ用
      enable_execute_command = true

      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = "/ecs/${local.project_key}-api",
          awslogs-region = "ap-northeast-1",
          awslogs-stream-prefix = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        { "name": "ENV", "value": "dev" }
      ]

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${local.project_key}-api-service"
  depends_on      = [aws_lb.alb]
  launch_type     = "FARGATE"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2

  #   更新されたコンテナイメージをタスクに使用する場合は、ECSの新しいデプロイを強制する
  force_new_deployment = true

  network_configuration {
    subnets          = data.aws_subnets.public_subnets.ids
    security_groups  = [data.aws_security_group.api_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_target_group.arn
    container_name   = "${local.project_key}-api"
    container_port   = 8080
  }
}