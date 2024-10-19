################# iam #################
resource "aws_iam_role" "ecs_task_role_batch" {
  name = "${local.project_key}-ecs-task-role-batch"

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

# 共通設定
resource "aws_iam_role_policy_attachment" "cloudwatch_batch" {
  role       = aws_iam_role.ecs_task_role_batch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_batch" {
  role       = aws_iam_role.ecs_task_role_batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr_batch" {
  role       = aws_iam_role.ecs_task_role_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 固有の設定
resource "aws_iam_role_policy_attachment" "dynamodb_batch" {
  role       = aws_iam_role.ecs_task_role_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

################# ecs #################
module "log_group_batch" {
  version           = "5.4.0"
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  name              = "/ecs/${local.project_key}-batch"
  retention_in_days = 120
}

resource "aws_ecs_service" "batch" {
  name            = "${local.project_key}-batch-service"
  depends_on      = [aws_iam_role.ecs_task_role_batch]
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.batch.arn
  desired_count   = 1

  #   更新されたコンテナイメージをタスクに使用する場合は、ECSの新しいデプロイを強制する
  force_new_deployment = true

  network_configuration {
    subnets          = data.aws_subnets.public_subnets.ids
    security_groups  = [data.aws_security_group.batch_sg.id]
    assign_public_ip = true
  }

  // deployに失敗したらロールバックする
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  // サービスが停止したらアラームを通知する。ロールバックもする
  alarms {
    alarm_names = ["${local.project_key}-ai-service"]
    enable      = true
    rollback    = true
  }

  # fargate_spotを使用する設定
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}


resource "aws_ecs_task_definition" "batch" {
  family                   = "${local.project_key}-batch-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role_batch.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name  = "${local.project_key}-batch"
      image = "${aws_ecr_repository.batch.repository_url}:latest"

      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${local.project_key}-batch",
          awslogs-region        = "ap-northeast-1",
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { "name" : "ENV", "value" : "dev" }
      ]
    }
  ])
}
