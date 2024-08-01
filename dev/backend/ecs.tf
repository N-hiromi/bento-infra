################# ecs #################
module "ecs" {
  source             = "terraform-aws-modules/ecs/aws"
  cluster_name               = "${local.project_key}-cluster"
  cluster_settings          = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
  fargate_capacity_providers = [
    {
      name = "FARGATE"
      platform_version = "LATEST"
    },
    {
      name = "FARGATE_SPOT"
      platform_version = "LATEST"
    }
  ]
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
  policy_arn = "arn:aws:iam::204705984956:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
}
