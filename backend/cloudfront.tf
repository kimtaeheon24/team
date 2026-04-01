# 1. CloudFront Origin Access Control (S3 보안 강화)
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3_oac"
  description                       = "CloudFront OAC for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. CloudFront Distribution 생성
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3-Frontend"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # HTTP 접속 시 HTTPS로 강제 전환
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # 카카오맵 연동을 위해 필요한 가격 클래스 (가장 저렴한 옵션)
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 기본 cloudfront.net 인증서 사용
  }
}

# 3. 생성된 클라우드프론트 주소 출력
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
