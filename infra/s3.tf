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
    Statement = [{
      Sid       = "PublicReadGetter"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# 5. index.html 업로드 (API 주소를 자동으로 주입!)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  # tftpl 파일을 사용해 API 주소를 HTML 안에 자동으로 박아넣습니다.
  content      = templatefile("${path.module}/../src/frontend/index.html.tftpl", {
    API_BASE = aws_api_gateway_stage.dev.invoke_url
    API_URL  = aws_api_gateway_stage.dev.invoke_url
  })
  content_type = "text/html"
}
