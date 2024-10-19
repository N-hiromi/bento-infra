resource "aws_sqs_queue" "target_video_queue" {
  name                      = "${local.project_key}-target-video-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 90
}

resource "aws_sqs_queue" "result_video_queue" {
  name                      = "${local.project_key}-result-video-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 90
}

# -------------------------SQSポリシー-------------------------
resource "aws_sqs_queue_policy" "target_video_queue_policy" {
  queue_url = aws_sqs_queue.target_video_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.target_video_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn":  data.aws_s3_bucket.target_video_bucket.arn
          }
        }
      }
    ]
  })
}