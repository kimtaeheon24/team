# 1. 프론트엔드용 S3 버킷 생성
resource "aws_s3_bucket" "frontend" {
  bucket = "taeheon-map-project-2026-final-th" 
}

# 2. 정적 웹 사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
}

# 3. 퍼블릭 액세스 차단 (CloudFront 전용)
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. CloudFront 전용 버킷 정책
resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn }
      }
    }]
  })
}

# 5. [임시 우회] Cognito 에러를 방지하고 지도부터 띄우는 업로드 설정
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  
  content = templatefile("${path.module}/index.html", {
    # API 주소는 정상 연결
    BASE_URL     = "https://${aws_api_gateway_rest_api.map_api.id}.execute-api.ap-northeast-2.amazonaws.com/dev"
    
    # Cognito는 형식만 맞춰서 '더미(Dummy)' 값 입력 (에러 방지용)
    COGNITO_POOL = "ap-northeast-2_dummy123" 
    clientId     = "dummyclientid123456789012" 
    domain       = "dummy.auth.ap-northeast-2.amazoncognito.com"
    
    # 리다이렉트 URI는 현재 주소로 유지
    redirectUri  = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
  })

  content_type = "text/html"
}

# 6. 최종 접속 주소 출력
output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}