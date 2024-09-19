resource "aws_cognito_user_pool" "user_pool" {
  name = local.project_key

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  #   アカウントの作成は管理者のみならtrue
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  #   ユーザプールの削除を保護するかどうか
  deletion_protection = "ACTIVE"

  #   本人確認はメールで行う
  auto_verified_attributes = ["email"]

  #   サインイン必須属性
  alias_attributes = ["preferred_username", "email"]

  email_configuration {
    #     TODO 開発中は一旦cognitoから送信するようにする。
    email_sending_account = "COGNITO_DEFAULT"
    #     email_sending_account = "DEVELOPER"
    #   メール送信元設定
    #     from_email_address    = ""
    # SESで登録したemailAddressのarnを設定
    #     source_arn = ""
  }

  #   TODO パスワードポリシー設定必要?
  password_policy {
    minimum_length = 8
    #       小文字を一文字以上入れること
    require_lowercase = true
    #       数字を一文字以上入れること
    require_numbers = true
    #       記号を一文字以上入れること
    require_symbols = true
    #       大文字を一文字以上入れること
    require_uppercase = true
  }

  username_configuration {
    case_sensitive = true
  }

  #   TODO SESを使用している場合だけ設定が有効になる
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "検証コード"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${local.project_key}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  # アクセストークンの有効期限。単位は時間
  access_token_validity = 1
  # 認証セッションの有効期限を設定（単位は??。有効値は3 - 15）
  auth_session_validity = 3
  #   リフレッシュトークンの有効期限。単位は日数.60 分から 10 年まで
  refresh_token_validity = 1

  #   他のサービスの認証を使う機能
  #   TODO 項目が決まり次第修正する
  callback_urls = ["https://example.com"]
  #   ログイン後のリダイレクト先。
  default_redirect_uri = "https://example.com"
  #   ログアウト後のリダイレクト先
  logout_urls = ["https://example.com"]
  #   OAUTHを使うならtrue
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  #   supported_identity_providers         = ["COGNITO", "Google", "SignInWithApple"]
  # TODO googleとappleは手動でコンソールから設定する
  supported_identity_providers = ["COGNITO"]
}

# 他サービス認証ごとの設定
// google ------------------------------
resource "aws_cognito_user_group" "google" {
  name         = "${local.project_key}-google-user-group"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "google認証ユーザ"
}

# TODO googleの設定はこれは手動でコンソールからやる
# resource "aws_cognito_identity_provider" "google" {
#   user_pool_id  = aws_cognito_user_pool.user_pool.id
#   provider_name = "Google"
#   provider_type = "Google"
#   provider_details = {
#     authorize_scopes = "email profile openid"
#     client_id        = ""
#     client_secret    = ""
#   }
#   attribute_mapping = {
#     email    = "email"
#     preferred_username = "name"
#   }
# }

// apple ------------------------------
resource "aws_cognito_user_group" "apple" {
  name         = "${local.project_key}-apple-user-group"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "apple認証ユーザ"
}

//TODO appleの設定はこれは手動でコンソールからやる
# resource "aws_cognito_identity_provider" "apple" {
#   user_pool_id  = aws_cognito_user_pool.user_pool.id
#   provider_name = "SignInWithApple"
#   provider_type = "SignInWithApple"
#   provider_details = {
#     authorize_scopes = "email"
#     client_id        = ""
#     private_key      = ""
#     key_id           = ""
#     team_id          = ""
#   }
#   attribute_mapping = {
#     email    = "email"
#     preferred_username = "sub"
#   }
# }