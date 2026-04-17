resource "aws_s3_bucket" "frontend" {
  bucket = "map-project-frontend-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  depends_on = [aws_s3_bucket_public_access_block.frontend_block]

  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content      = file("${path.module}/../src/frontend/index.html")
  etag         = filemd5("${path.module}/../src/frontend/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.frontend.id
  key    = "config.js"

  content = templatefile("${path.module}/../src/frontend/config.js.tpl", {
    api_url           = aws_apigatewayv2_stage.dev.invoke_url
    user_pool_id      = aws_cognito_user_pool.pool.id
    client_id         = aws_cognito_user_pool_client.client.id
    auth_domain       = "${aws_cognito_user_pool_domain.main.domain}.auth.ap-northeast-2.amazoncognito.com"
    redirect_sign_in  = "https://www.kimtaeheon.store/"
    redirect_sign_out = "https://www.kimtaeheon.store/"
  })

  content_type = "application/javascript"
}