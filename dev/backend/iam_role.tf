resource "aws_iam_role" "api_role" {
  name = "${local.project_key}-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  # albとの通信を許可するポリシー
  inline_policy {
    name = "alb-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTargetGroups"
          ]
          #           TODO albのarnを指定する
          Resource = ["*"]
        }
      ]
    })
  }

  #   dynamodbとの通信を許可するポリシー
  inline_policy {
    name = "dynamo-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
#             TODO どんな処理をするのかわからないのでひととおり当てる
            "dynamodb:BatchGetItem",
            "dynamodb:BatchWriteItem",
            "dynamodb:DeleteItem",
            "dynamodb:DescribeTable",
            "dynamodb:GetItem",
            "dynamodb:ListTables",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:UpdateItem",
            "dynamodb:UpdateTable",
          ]
          #           TODO dynamoのarnを指定する
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_iam_role" "ai_role" {
  name = "${local.project_key}-ai-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  # sqsとの通信を許可するポリシー
  inline_policy {
    name = "upload-sqs-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueUrl"
          ]
          Resource = [aws_sqs_queue.target_video_queue.arn]
        }
      ]
    })
  }

  inline_policy {
    name = "result-sqs-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sqs:SendMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueUrl"
          ]
          Resource = [aws_sqs_queue.result_video_queue.arn]
        }
      ]
    })
  }
}

resource "aws_iam_role" "worker_role" {
  name = "${local.project_key}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  # snsへの送信を許可するポリシー
  inline_policy {
    name = "send-sns-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "SendToSNS"
          Effect = "Allow"
          Action = "sns:Publish"
          Resource = [
            aws_sns_topic.notify_to_mobile.arn
          ]
        }
      ]
    })
  }

  #   dynamodbとの通信を許可するポリシー
  inline_policy {
    name = "dynamo-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem"
          ]
          #           TODO dynamoのarnを指定する
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_iam_role" "batch_role" {
  name = "${local.project_key}-batch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  #   dynamodbとの通信を許可するポリシー
  inline_policy {
    name = "dynamo-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:BatchWriteItem",
          ]
          #           TODO dynamoのarnを指定する
          Resource = ["*"]
        }
      ]
    })
  }
}

# それぞれのロールをインスタンスプロフィールにする
resource "aws_iam_instance_profile" "api_instance_profile" {
  name = "${local.project_key}-api-role"
  role = aws_iam_role.api_role.name
}

resource "aws_iam_instance_profile" "aii_instance_profile" {
  name = "${local.project_key}-ai-role"
  role = aws_iam_role.ai_role.name
}

resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "${local.project_key}-worker-role"
  role = aws_iam_role.worker_role.name
}

resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "${local.project_key}-api-role"
  role = aws_iam_role.batch_role.name
}