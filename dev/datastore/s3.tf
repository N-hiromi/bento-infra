# -------------------------バケット-------------------------
// 顧客がアップロードした動画を保存するためのS3バケット
resource "aws_s3_bucket" "target_video_bucket" {
  bucket              = "${local.project_key}-target-video-bucket"
  object_lock_enabled = true
}

// 解析後動画を保存するためのS3バケット
resource "aws_s3_bucket" "result_video_bucket" {
  bucket              = "${local.project_key}-result-video-bucket"
  object_lock_enabled = true
}

# 学習データを保存するためのS3バケット
resource "aws_s3_bucket" "learning_data_bucket" {
  bucket              = "${local.project_key}-learning-data-bucket"
  object_lock_enabled = true
}

# -------------------------バケットポリシー-------------------------
// 顧客が特定のパスに動画をアップロードできるようにするポリシー
resource "aws_s3_bucket_policy" "target_video_bucket_policy" {
  bucket = aws_s3_bucket.target_video_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS": data.aws_iam_role.identity_pool_role.arn
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.target_video_bucket.arn}/upload/$${cognito-identity.amazonaws.com:sub}/*"
      }
    ]
  })
}

// 解析後動画を特定のパスから取得できるようにするポリシー
resource "aws_s3_bucket_policy" "result_video_bucket_policy" {
  bucket = aws_s3_bucket.result_video_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS": data.aws_iam_role.identity_pool_role.arn
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.result_video_bucket.arn}/upload/$${cognito-identity.amazonaws.com:sub}/*"
      }
    ]
  })
}

// -------------------------バケットイベント通知-------------------------
// 顧客が動画をアップロードした際に、sqsへ通知する
resource "aws_s3_bucket_notification" "target_video_bucket_notification" {
  bucket = aws_s3_bucket.target_video_bucket.bucket

  queue {
    queue_arn     = data.aws_sqs_queue.target_video_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "upload/"
  }
}