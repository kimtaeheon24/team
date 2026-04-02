# 1. 프론트엔드용 S3 버킷 생성
resource "aws_s3_bucket" "frontend" {
  bucket = "map-project-frontend-${random_string.suffix.result}" # 중복 방지를 위해 랜덤값 추가
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. 정적 웹 호스팅 설정
resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

# 3. 퍼블릭 액세스 차단 해제 (웹사이트니까 열어줘야 함)
resource "aws_s3_bucket_public_access_block" "open" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. 버킷 정책 (누구나 읽을 수 있게)
resource "aws_s3_bucket_policy" "allow_public" {
  depends_on = [aws_s3_bucket_public_access_block.open]
  bucket     = aws_s3_bucket.frontend.id
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      Sid       = "PublicReadGetter"
      Effect    = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
        }
      }
    }]
  })
}

# 5. index.html 업로드 (API 주소를 자동으로 주입!)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  # tftpl 파일을 사용해 API 주소를 HTML 안에 자동으로 박아넣습니다.
  source      = "${path.module}/../src/frontend/index.html"
  content_type = "text/html"
  etag = filemd5("${path.module}/../src/frontend/index.html")
}

resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  
  # content 안에 4가지 항목이 모두 들어있는지 꼭 확인하세요!
  content = <<-EOF
    window.APP_CONFIG = {
      API_BASE_URL: "${aws_apigatewayv2_stage.dev.invoke_url}",
      USER_POOL_ID: "${aws_cognito_user_pool.pool.id}",
      CLIENT_ID: "${aws_cognito_user_pool_client.client.id}",
      AUTH_DOMAIN: "${aws_cognito_user_pool_domain.main.domain}.auth.ap-northeast-2.amazoncognito.com"
    };
  EOF

  # etag가 있어야 파일 내용 변경을 테라폼이 감지하고 S3에 덮어씁니다.
  etag = md5(<<-EOF
    window.APP_CONFIG = {
      API_BASE_URL: "${aws_apigatewayv2_stage.dev.invoke_url}",
      USER_POOL_ID: "${aws_cognito_user_pool.pool.id}",
      CLIENT_ID: "${aws_cognito_user_pool_client.client.id}",
      AUTH_DOMAIN: "${aws_cognito_user_pool_domain.main.domain}.auth.ap-northeast-2.amazoncognito.com"
    };
  EOF
  )

  content_type = "application/javascript"
}

# S3 오브젝트(config.js 등)가 변경될 때만 실행됩니다.
resource "null_resource" "invalidate_cache" {
  triggers = {
    # config.js나 index.html이 바뀔 때마다 실행되도록 설정
    config_hash = aws_s3_object.config.etag
    index_hash  = aws_s3_object.index.etag
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths '/*'"
  }
}