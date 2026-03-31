# 1. 사용자 풀 (User Pool) 설정
resource "aws_cognito_user_pool" "pool" {
  name = "kakaomap-user-pool"

  # 이메일을 아이디로 사용하도록 설정
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"] # 가입 시 이메일 인증 코드 자동 발송

  # 비밀번호 정책 (콘솔의 '비밀번호 정책' 부분)
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # 계정 복구 설정
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # 사용자 속성 설정 (이메일 필수)
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

# 2. 앱 클라이언트 (App Client) 설정
resource "aws_cognito_user_pool_client" "client" {
  name         = "kakaomap-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  # 인증 방식 설정 (아이디/비밀번호 로그인 허용)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH", # 일반적인 아이디/비밀번호 방식
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # CloudFront 주소와 연결 (이 부분이 자동화의 핵심!)
  callback_urls = ["https://${aws_cloudfront_distribution.s3_distribution.domain_name}/"]
  logout_urls   = ["https://${aws_cloudfront_distribution.s3_distribution.domain_name}/"]

  allowed_oauth_flows                  = ["implicit"] # Implicit 방식 사용 시
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  
  supported_identity_providers = ["COGNITO"]
}

# 3. 사용자 풀 도메인 (로그인 화면 주소)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "kakaomap-auth-${random_id.id.hex}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "random_id" "id" {
  byte_length = 4
}