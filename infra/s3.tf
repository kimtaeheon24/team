resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  
  # src 폴더의 템플릿 파일을 읽어와서 변수들(BASE_URL 등)을 꽂아넣음
  content = templatefile("${path.module}/../src/frontend/index.html.tftpl", {
    BASE_URL        = "https://${aws_api_gateway_rest_api.map_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    REVIEWS_API_URL = "https://${aws_api_gateway_rest_api.map_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    # 아까 에러 났던 변수들도 여기서 미리 처리 가능
    place           = "", name = "", id = "", lat = "37.5665", lng = "126.9780"
  })

  content_type = "text/html"
}
