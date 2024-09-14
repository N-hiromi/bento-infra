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
# resource "aws_s3_bucket_policy" "target_video_bucket_policy" {
#   bucket = aws_s3_bucket.target_video_bucket.bucket
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           "AWS": "arn:aws:sts::166448729741:assumed-role/nnaabbee_tidy_sample_id_pool_role/CognitoIdentityCredentials"
#         },
#         Action = [
#           "s3:PutObject"
#         ],
#         Resource = format("${aws_s3_bucket.target_video_bucket.arn}/cognito/accounts/%s/*", "cognito-identity.amazonaws.com:sub")
#       }
#     ]
#   })
# }
#
# resource "aws_s3_bucket_policy" "result_video_bucket_policy" {
#   bucket = aws_s3_bucket.result_video_bucket.bucket
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           "AWS": "arn:aws:sts::166448729741:assumed-role/nnaabbee_tidy_sample_id_pool_role/CognitoIdentityCredentials"
#         },
#         Action = [
#           "s3:GetObject"
#         ],
#         Resource = format("${aws_s3_bucket.result_video_bucket.arn}/cognito/accounts/%s/*", "cognito-identity.amazonaws.com:sub")
#       }
#     ]
#   })
# }