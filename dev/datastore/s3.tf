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
