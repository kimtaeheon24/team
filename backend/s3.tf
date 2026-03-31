resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = "taeheon-jennie-tfstate-2026"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "kakao-map-project-bucket" 
}

resource "aws_s3_bucket_website_configuration" "type" {
  bucket = aws_s3_bucket.website_bucket.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  
  # 진짜 테라폼이 주입해야 할 5가지 변수만 남겼습니다.
  content = templatefile("${path.module}/../frontend/index.html.tftpl", {
    BASE_URL     = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/api"
    COGNITO_POOL = aws_cognito_user_pool.pool.id
    clientId     = aws_cognito_user_pool_client.client.id
    domain       = aws_cloudfront_distribution.s3_distribution.domain_name
    redirectUri  = "https://d1saktp8jdqnjr.cloudfront.net" # 혹은 변수 처리
  })
  
  content_type = "text/html"
  depends_on   = [aws_cloudfront_distribution.s3_distribution]
}