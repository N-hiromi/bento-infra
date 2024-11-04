# apply時にclient_secretを渡すこと
variable "client_secret" {
  description = "googleのclient_secret"
  type        = string
}

# user-pool ------------------------------
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
  #   TODO 検証が終わったらactiveにすること
  #   deletion_protection = "ACTIVE"

  #   本人確認はメールで行う
  auto_verified_attributes = ["email"]

  #   ユーザ名の属性
  username_attributes = ["email"]

  #   ユーザプールの属性
  #   custom属性のusername。defaultのusernameはemailを指す
  schema {
    attribute_data_type = "String"
    name                = "username"
    required            = false
    mutable             = false
  }
  schema {
    attribute_data_type = "String"
    name                = "email"
    #     ログインに使うのでtrue
    required = true
    #     変更可能かどうか
    mutable = true
  }

  #   属性を更新する際に確認を行う
  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

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
  callback_urls = [
    "https://tidy-ai.com/home"
  ]
  #   ログイン後のリダイレクト先。
  default_redirect_uri = "https://tidy-ai.com/home"
  #   ログアウト後のリダイレクト先
  logout_urls = ["https://tidy-ai.com/welcome"]
  #   OAUTHを使うならtrue
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # クライアントの認証フロー
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH",
  ]
}

# cognitoドメインを追加
resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "${local.project_key}-domain"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# -----------idプール-------------------
# Idプールを使うのに必要な最低限のiamロール
resource "aws_iam_role" "identity_pool_role" {
  name = "${local.project_key}-identity-pool-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          },
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      },
    ]
  })
}

# GetCredentialsForIdentityを含むawsのロールがなかったのでポリシーをアタッチする
resource "aws_iam_policy" "identity_pool_policy" {
  name = "${local.project_key}-get-credentials-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "cognito-identity:GetCredentialsForIdentity"
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

# iamロールへポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "identity_pool_policy" {
  role       = aws_iam_role.identity_pool_role.name
  policy_arn = aws_iam_policy.identity_pool_policy.arn
}

# idプールにロールをアタッチ
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id
  roles = {
    "authenticated" = aws_iam_role.identity_pool_role.arn
  }
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${local.project_key}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = false
  }
}