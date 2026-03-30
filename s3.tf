# 1. 프론트엔드 S3 버킷 생성
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "kimtaeheon-map-project-frontend" # 중복 방지를 위해 고유한 이름 사용
}

# 2. 퍼블릭 액세스 차단 해제 (웹사이트 공개를 위해 필수)
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. 정적 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# 4. 버킷 정책 (외부에서 접속 가능하게 허용)
resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# 5. ★핵심: index.html 파일을 자동으로 S3에 업로드하는 코드★
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  
  # ⭐ 이 줄이 핵심입니다! 파일의 지문을 찍어서 변화를 감지하게 만듭니다.
  etag = filemd5("${path.module}/index.html")
}

# 6. 접속 주소 출력
output "website_url" {
  value = aws_s3_bucket_website_configuration.frontend_config.website_endpoint
}