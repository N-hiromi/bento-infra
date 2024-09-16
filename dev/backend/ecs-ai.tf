################# iam #################
resource "aws_iam_role" "ecs_task_role_ai" {
  name = "${local.project_key}-ecs_task_role_ai"

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
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


################# コンテナインスタンスへのiam #################
resource "aws_iam_role" "ecs_instance_role_ai" {
  name = "${local.project_key}-ecs_instance_role_ai"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_to_instance_ai" {
  role       = aws_iam_role.ecs_instance_role_ai.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// EC2インスタンスにIAMロールを指定するには、インスタンスプロファイルを作成する必要がある
resource "aws_iam_instance_profile" "ecs_instance_profile_ai" {
  name = "${local.project_key}-ecs-instance-profile-ai"
  role = aws_iam_role.ecs_instance_role_ai.name
}

################# ecs #################
module "log_group_ai" {
  version           = "5.4.0"
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  name              = "/ecs/${local.project_key}-ai"
  retention_in_days = 120
}

resource "aws_autoscaling_group" "ai" {
  name                 = "${local.project_key}-ai-asg"
  max_size             = 1
  min_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = data.aws_subnets.public_subnets.ids
  launch_template {
    id      = aws_launch_template.ai.id
   // こいつoptionalとか書いてあったのに書かないとmax spot instance exceededになる
    version = "$Latest"
  }
}

resource "aws_launch_template" "ai" {
  name_prefix          = "${local.project_key}-ai-lc"
  image_id             = "ami-0168a81614b20b0f8"
  instance_type        = "g4dn.xlarge"
  key_name             = data.aws_key_pair.key.key_name

  # コンテナインスタンスへのIAMロールを指定
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile_ai.name
  }

  instance_market_options {
    market_type = "spot"  # スポットインスタンスを指定
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 100
      volume_type = "gp3"
    }
  }

  // EC2インスタンス起動時にECSクラスタへインスタンスを登録するための設定. ebsのリサイズも行う
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
              sudo resize2fs /dev/nvme0n1p1
              EOF
            )

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [data.aws_security_group.ai_sg.id]
  }

  tag_specifications {
      resource_type = "instance"
      tags = {
      Name = "${local.project_key}-ai"
      }
  }
}

resource "aws_ecs_task_definition" "ai" {
  family                   = "${local.project_key}-ai-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_role_ai.arn
  requires_compatibilities = ["EC2"]
  cpu                      = 1000
  memory                   = 2000

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name = "${local.project_key}-ai"
      image     = "${aws_ecr_repository.ai.repository_url}:latest"

      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${local.project_key}-ai"
          awslogs-region = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      resource_requirements = [{
        type  = "GPU"
        value = "1"  # 利用するGPUの数
      }]
      // TODO コンテナを立ち上げっぱなしにする。
      pseudo_terminal = true
    }
  ])
}

resource "aws_ecs_service" "ai" {
  name            = "${local.project_key}-ai-service"
  depends_on      = [aws_iam_role.ecs_task_role_ai]
  launch_type     = "EC2"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ai.arn
  desired_count   = 1
#   更新されたコンテナイメージをタスクに使用する場合は、ECSの新しいデプロイを強制する
  force_new_deployment = true

  // deployに失敗したらロールバックする
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  // サービスが停止したらアラームを通知する。ロールバックもする
  alarms {
    alarm_names = ["${local.project_key}-ai-service"]
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = data.aws_subnets.public_subnets.ids
    security_groups  = [data.aws_security_group.ai_sg.id]
  }
}