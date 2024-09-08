################# iam #################
resource "aws_iam_role" "ecs_task_role_ai" {
  name = "${local.project_key}-ecs-task-role-3d-pose"

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
resource "aws_iam_role_policy_attachment" "cloudwatch_log_ai" {
  role       = aws_iam_role.ecs_task_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_ai" {
  role       = aws_iam_role.ecs_task_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr_ai" {
  role       = aws_iam_role.ecs_task_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

# 固有の設定
resource "aws_iam_role_policy_attachment" "sqs_ai" {
  role       = aws_iam_role.ecs_task_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_ai" {
  role       = aws_iam_role.ecs_task_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

################# ecs #################
module "log_group_ai" {
  version           = "5.4.0"
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  name              = "/ecs/${local.project_key}-ai"
  retention_in_days = 120
}

resource "aws_ecs_task_definition" "ai" {
  family                   = "${local.project_key}-ai-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role_ai.arn
  requires_compatibilities = ["EC2"]
  cpu                      = 4096
  memory                   = 16384

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name = "${local.project_key}-ai"
      image     = "${aws_ecr_repository.ai.repository_url}:latest"

      # TODO デバッグ用
      enable_execute_command = true

      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${local.project_key}-ai"
          awslogs-region = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ai" {
  name            = "${local.project_key}-ai-service"
  depends_on      = [aws_iam_role.ecs_task_role_ai]
  launch_type     = "EC2"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.ai.arn
  desired_count   = 2
#   更新されたコンテナイメージをタスクに使用する場合は、ECSの新しいデプロイを強制する
  force_new_deployment = true

  network_configuration {
    subnets          = data.aws_subnets.public_subnets.ids
    security_groups  = [data.aws_security_group.ai_sg.id]
  }
}