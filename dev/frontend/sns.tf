# dynamoへの登録をモバイルに通知するsns-topic
resource "aws_sns_topic" "notify_to_mobile" {
  name = "${local.project_key}-notify-to-mobile"
}

# TODO subscription まとめて全てのデバイスに送られる。イベントがあったデバイスごとに送りたいので今回は使わないかも
# # iphone用
# resource "aws_sns_topic_subscription" "notify_to_apple" {
#   topic_arn = aws_sns_topic.notify_to_mobile.arn
#   protocol  = "application"
# このエンドポイントはプラットフォームアプリケーションのARNではなく、プラットフォームアプリケsーションに紐ずくデバイスのARNを指定する
#   endpoint  = aws_sns_platform_application.apple.arn
# }
#
# # android用
# resource "aws_sns_topic_subscription" "notify_to_android" {
#   topic_arn = aws_sns_topic.notify_to_mobile.arn
#   protocol  = "application"
# このエンドポイントはプラットフォームアプリケーションのARNではなく、プラットフォームアプリケsーションに紐ずくデバイスのARNを指定する
#   endpoint  = aws_sns_platform_application.android.arn
# }

# プラットフォームアプリケーション
# iphone用
resource "aws_sns_platform_application" "apple" {
  name     = "${local.project_key}-apple"
  platform = "APNS"
  #   todo
  platform_credential = "<APNS PRIVATE KEY>"
  platform_principal  = "<APNS CERTIFICATE>"
}

# android用
resource "aws_sns_platform_application" "android" {
  name     = "${local.project_key}-android"
  platform = "FCM"
  #   todo
  platform_credential = "<FCM API KEY>"
}