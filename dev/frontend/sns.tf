# プラットフォームアプリケーション
# iphone用
# resource "aws_sns_platform_application" "apple" {
#   name     = "${local.project_key}-apple"
#   platform = "APNS"
#   #   todo
#   platform_credential = "<APNS PRIVATE KEY>"
#   platform_principal  = "<APNS CERTIFICATE>"
# }
#
# # android用
# resource "aws_sns_platform_application" "android" {
#   name     = "${local.project_key}-android"
#   platform = "FCM"
#   #   todo
#   platform_credential = "<FCM API KEY>"
# }