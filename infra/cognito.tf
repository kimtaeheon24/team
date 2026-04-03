resource "aws_cognito_user_pool" "pool" {
  name                     = "map_user_pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length = 8
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "suhyeon-map-auth" # 유니크해야 함
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "map_app_client"
  user_pool_id = aws_cognito_user_pool.pool.id

  supported_identity_providers = ["COGNITO"]

  # 🔥 여기 중요 (너 CloudFront 주소)
  callback_urls = ["https://d28bqzc88yd66y.cloudfront.net/"]
  logout_urls   = ["https://d28bqzc88yd66y.cloudfront.net/"]

  # 🔥 핵심 설정 (이거 때문에 지금 문제였음)
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit"] # ❗ code 제거
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

output "auth_domain_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.ap-northeast-2.amazoncognito.com"
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}