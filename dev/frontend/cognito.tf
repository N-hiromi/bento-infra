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

  #   ユーザ名の属性を指定
  username_attributes = ["preferred_username"]

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
  #   メールテンプレートの設定
  invite_message_template {
    email_message = "Your username is {username} and temporary password is {####}."
    email_subject = "Your temporary password"
  }

  #   TODO SESを使用している場合だけ設定が有効になる
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "検証コード"
  }

  tags = {
    Env = "${dirname(path_relative_to_include())}"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = local.project_key
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
  supported_identity_providers         = ["COGNITO", "Facebook", "Google", "SignInWithApple", "LoginWithAmazon"]
}

# TODO 認証に使う外部サービスが決まったら設定する
# 他サービス認証ごとの設定
resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "Google"
  provider_type = "Google"
  provider_details = {
    authorize_scopes = "email"
    client_id        = aws_cognito_user_pool_client.client.id
    client_secret    = aws_cognito_user_pool_client.client.client_secret
  }
  attribute_mapping = {
    email    = "email"
    username = "preferred_username"
  }
}