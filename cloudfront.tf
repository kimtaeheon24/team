# 1. CloudFront Origin Access Control (OAC) 생성
# S3 버킷을 비공개로 전환하고 CloudFront를 통해서만 접속하게 만드는 최신 보안 방식입니다.
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. CloudFront Distribution 설정
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # 캐시 설정 (기본값)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https" # 중요: HTTP로 들어와도 HTTPS로 강제 전환
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 도메인 연결 전에는 기본 인증서 사용
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 3. CloudFront 주소 출력
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
