resource "aws_s3_bucket" "website_bucket" {
  bucket = "kakao-map-project-bucket" # 전 세계 중복되지 않는 고유한 이름으로 수정하세요
}

# S3 웹사이트 호스팅 설정 (기본 문서 설정)
resource "aws_s3_bucket_website_configuration" "type" {
  bucket = aws_s3_bucket.website_bucket.id
  index_document { suffix = "index.html" }
}

# 외부에서 직접 접근하는 것을 차단 (보안)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# s3.tf 맨 밑에 추가하세요
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  
  # 템플릿 파일을 읽어서 api_url 변수에 CloudFront 주소를 주입합니다.
  content      = templatefile("${path.module}/index.html.tftpl", {
    api_url = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/api"
  })
  
  content_type = "text/html"

  # CloudFront가 생성된 후에 업로드되도록 순서를 보장합니다.
  depends_on = [aws_cloudfront_distribution.s3_distribution]
}