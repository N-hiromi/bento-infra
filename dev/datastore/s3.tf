# -------------------------バケット-------------------------
// 顧客がアップロードした動画を保存するためのS3バケット
resource "aws_s3_bucket" "bento_image_bucket" {
  bucket              = "${local.project_key}-bento-image-bucket"
  object_lock_enabled = true
}
# -------------------------バケットポリシー-------------------------
// 顧客が特定のパスに画像をアップロードとダウンロードできるようにするポリシー
resource "aws_s3_bucket_policy" "target_video_bucket_policy" {
  bucket = aws_s3_bucket.bento_image_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS": data.aws_iam_role.identity_pool_role.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.bento_image_bucket.arn}/$${cognito-identity.amazonaws.com:sub}/*"
      }
    ]
  })
}
