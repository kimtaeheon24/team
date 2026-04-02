# 1. API 게이트웨이 생성 (HTTP API v2)
resource "aws_apigatewayv2_api" "map_api" {
  name          = "MapProject-API"
  description   = "맛집 지도 프로젝트 통합 API (v2)"
  protocol_type = "HTTP"

  # CORS 설정을 여기서 한 방에 끝냅니다!
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

# 2. 스테이지 및 자동 배포 설정 (v2는 배포가 훨씬 쉽습니다)
resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.map_api.id
  name        = "dev"
  auto_deploy = true # 변경사항이 생기면 자동으로 배포해줍니다!
}

# 3. 람다 통합 (Integration) - v2 전용
resource "aws_apigatewayv2_integration" "lambda_int" {
  for_each = aws_lambda_function.functions

  api_id           = aws_apigatewayv2_api.map_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = each.value.invoke_arn
  payload_format_version = "2.0" # v2의 표준 형식
}

# 4. 라우팅 설정 (Route) - 메서드와 경로를 한 번에 정의!
# GET /restaurants
resource "aws_apigatewayv2_route" "get_restaurants" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "GET /restaurants"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["get_restaurants"].id}"
}

# GET /reviews
resource "aws_apigatewayv2_route" "get_reviews" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "GET /reviews"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["get_reviews"].id}"
  authorization_type = "NONE"
}

# POST /reviews
resource "aws_apigatewayv2_route" "post_review" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "POST /reviews"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["post_review"].id}"
}

# POST /bookmarks
resource "aws_apigatewayv2_route" "post_bookmark" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "POST /bookmarks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["post_bookmark"].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_review" {
  api_id             = aws_apigatewayv2_api.map_api.id
  route_key          = "DELETE /reviews"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_int["post_review"].id}" # post_review.py에서 삭제 로직도 같이 처리 가능합니다.
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# 5. 람다 호출 권한 부여
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = aws_lambda_function.functions
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  
  # v2의 execution_arn 형식을 사용합니다.
  source_arn    = "${aws_apigatewayv2_api.map_api.execution_arn}/*/*"
}

# 6. 출력값 (Invoke URL)
output "api_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}

# [추가] 1. Cognito Authorizer 설정
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.map_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    # cognito.tf에서 만든 클라이언트 ID와 풀 엔드포인트를 참조합니다.
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.ap-northeast-2.amazonaws.com/${aws_cognito_user_pool.pool.id}"
  }
}