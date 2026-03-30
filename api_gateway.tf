# 1. API Gateway 생성 (HTTP API 방식)
resource "aws_apigatewayv2_api" "map_api" {
  name          = "map-project-api"
  protocol_type = "HTTP"
  
  # CORS 설정: CloudFront 도메인에서의 접속을 명확히 허용
  cors_configuration {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    # 조쉬님의 실제 CloudFront 주소를 넣어 브라우저 보안 차단을 해제합니다.
    allow_origins = ["https://d21v20pgzmqw2r.cloudfront.net"] 
    allow_credentials = true
    max_age = 300
  }
}

# 2. API 스테이지 설정
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.map_api.id
  name        = "prod"
  auto_deploy = true
}

# 3. 람다 연동 (Integrations)
resource "aws_apigatewayv2_integration" "get_restaurants" {
  api_id           = aws_apigatewayv2_api.map_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_restaurants.invoke_arn
}

resource "aws_apigatewayv2_integration" "review_handler" {
  api_id           = aws_apigatewayv2_api.map_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.review_handler.invoke_arn
}

resource "aws_apigatewayv2_integration" "bookmark_handler" {
  api_id           = aws_apigatewayv2_api.map_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.bookmark_handler.invoke_arn
}

# 4. 경로(Route) 설정
resource "aws_apigatewayv2_route" "get_restaurants_route" {
  api_id    = aws_apigatewayv2_api.map_api.id
  target    = "integrations/${aws_apigatewayv2_integration.get_restaurants.id}"
  route_key = "GET /restaurants"
}

resource "aws_apigatewayv2_route" "review_handler_route" {
  api_id    = aws_apigatewayv2_api.map_api.id
  target    = "integrations/${aws_apigatewayv2_integration.review_handler.id}"
  route_key = "ANY /reviews"
}

resource "aws_apigatewayv2_route" "bookmark_handler_route" {
  api_id    = aws_apigatewayv2_api.map_api.id
  target    = "integrations/${aws_apigatewayv2_integration.bookmark_handler.id}"
  route_key = "ANY /bookmarks"
}

# 5. 람다 호출 권한 부여
resource "aws_lambda_permission" "api_gw_get" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_restaurants.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.map_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_review" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.review_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.map_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_bookmark" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bookmark_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.map_api.execution_arn}/*/*"
}

# 6. 최종 API 주소 출력
output "api_endpoint" {
  value = "${aws_apigatewayv2_stage.prod.invoke_url}"
}