################# ecs #################
resource "aws_ecs_cluster" "cluster" {
  name = "${local.project_key}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]

  #   default_capacity_provider_strategy {
  #     capacity_provider = "FARGATE"
  #     weight            = 1
  #   }
  // TODO 一旦100%FARGATE_SPOTにしておく
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.project_key}-ecs-task-execution-role"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
