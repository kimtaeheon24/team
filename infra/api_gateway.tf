# 1. API 게이트웨이 생성 (HTTP API v2)
resource "aws_apigatewayv2_api" "map_api" {
  name          = "MapProject-API"
  description   = "맛집 지도 프로젝트 통합 API (v2)"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

# 2. 스테이지 설정 (v2는 deployment를 따로 선언할 필요 없이 auto_deploy만 켜면 됩니다)
resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.map_api.id # 명칭 통일: map_api
  name        = "dev"
  auto_deploy = true # v2의 핵심 장점!
}

# 3. 람다 통합 (Integration)
resource "aws_apigatewayv2_integration" "lambda_int" {
  for_each = aws_lambda_function.functions

  api_id                 = aws_apigatewayv2_api.map_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.invoke_arn
  payload_format_version = "2.0"
}

# 4. 라우팅 설정
resource "aws_apigatewayv2_route" "get_restaurants" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "GET /restaurants"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["get_restaurants"].id}"
}

resource "aws_apigatewayv2_route" "get_reviews" {
  api_id    = aws_apigatewayv2_api.map_api.id
  route_key = "GET /reviews"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int["get_reviews"].id}"
}

resource "aws_apigatewayv2_route" "post_review" {
  api_id             = aws_apigatewayv2_api.map_api.id
  route_key          = "POST /reviews"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_int["post_review"].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_bookmark" {
  api_id             = aws_apigatewayv2_api.map_api.id
  route_key          = "POST /bookmarks"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_int["post_bookmark"].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_review" {
  api_id             = aws_apigatewayv2_api.map_api.id
  route_key          = "DELETE /reviews"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_int["post_review"].id}"
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
  source_arn    = "${aws_apigatewayv2_api.map_api.execution_arn}/*/*"
}

# 6. Cognito Authorizer 설정
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.map_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.ap-northeast-2.amazonaws.com/${aws_cognito_user_pool.pool.id}"
  }
}

# 7. 출력값 (이 주소를 config.js에 넣으시면 됩니다)
output "api_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}