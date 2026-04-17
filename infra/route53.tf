# Route53 Hosted Zone 조회
data "aws_route53_zone" "main" {
  name         = "kimtaeheon.store"
  private_zone = false
}

# 루트 도메인 → CloudFront
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "kimtaeheon.store"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# www 도메인 → CloudFront
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.kimtaeheon.store"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# 확인용 출력
output "route53_zone_id" {
  value = data.aws_route53_zone.main.zone_id
}

output "root_domain" {
  value = aws_route53_record.root.fqdn
}

output "www_domain" {
  value = aws_route53_record.www.fqdn
}
