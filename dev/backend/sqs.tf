resource "aws_sqs_queue" "target_video_queue" {
  name                      = "${local.project_key}-target-video-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "result_video_queue" {
  name                      = "${local.project_key}-result-video-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}