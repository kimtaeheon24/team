# 1. User Pool 생성 (기존과 동일하되 도메인 연결을 위해 유지)
resource "aws_cognito_user_pool" "pool" {
  name                     = "map_user_pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length = 8
  }
}

# 2. Cognito 도메인 설정 (관리형 로그인 페이지 접속을 위한 주소)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "suhyeon-map-auth" # 중복되지 않는 고유한 이름을 지어주세요
  user_pool_id = aws_cognito_user_pool.pool.id
}

# 3. Client 설정 (OAuth 및 Hosted UI 활성화)
resource "aws_cognito_user_pool_client" "client" {
  name         = "map_app_client"
  user_pool_id = aws_cognito_user_pool.pool.id

  # 관리형 UI를 쓰기 위해 필요한 설정들
  supported_identity_providers = ["COGNITO"]
  
  # 로그인/로그아웃 성공 후 돌아올 S3 웹사이트 주소를 적어주세요
  callback_urls = ["https://d28bqzc88yd66y.cloudfront.net/"]
  logout_urls   = ["https://d28bqzc88yd66y.cloudfront.net/"]

  # OAuth 2.0 설정
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# 4. 추가된 Output (관리형 로그인 페이지 주소를 바로 확인하기 위함)
output "auth_domain_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.ap-northeast-2.amazoncognito.com"
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}