# 1. API Gateway 생성
resource "aws_api_gateway_rest_api" "map_api" {
  name        = "MapProjectAPI"
  description = "Restaurant Map Service API with CORS"
}

# 1. /api 리소스 생성
resource "aws_api_gateway_resource" "api_root" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "api" # 여기서 /api 경로가 생깁니다.
}

# 2. 기존 리소스들의 parent_id를 위 api_root의 id로 변경
resource "aws_api_gateway_resource" "restaurants" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_resource.api_root.id # root_resource_id 대신 이걸로!
  path_part   = "restaurants"
}

resource "aws_api_gateway_resource" "bookmarks" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_resource.api_root.id
  path_part   = "bookmarks"
}

resource "aws_api_gateway_resource" "reviews" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_resource.api_root.id
  path_part   = "reviews"
}

# 3. CORS 설정을 위한 OPTIONS 메서드 추가 및 Mock 통합 설정
resource "aws_api_gateway_method" "options_restaurants" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.restaurants.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_restaurants_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.restaurants.id
  http_method             = aws_api_gateway_method.options_restaurants.http_method
  integration_http_method = "ANY"
  type                    = "MOCK"
}

resource "aws_api_gateway_method_response" "options_restaurants_method_response" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  resource_id = aws_api_gateway_resource.restaurants.id
  http_method = aws_api_gateway_method.options_restaurants.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "options_restaurants_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  resource_id = aws_api_gateway_resource.restaurants.id
  http_method = aws_api_gateway_method.options_restaurants.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST, OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, Authorization'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

# [GET] /restaurants
resource "aws_api_gateway_method" "get_restaurants" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.restaurants.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"  # 인증 방식 설정
  authorizer_id = "s66h90"  # 생성된 Cognito 권한 부여자 ID
}

resource "aws_api_gateway_integration" "get_restaurants_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.restaurants.id
  http_method             = aws_api_gateway_method.get_restaurants.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_restaurants.invoke_arn
}

# [POST] /bookmarks
resource "aws_api_gateway_method" "post_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"  # 인증 방식 설정
  authorizer_id = "s66h90"  # 생성된 Cognito 권한 부여자 ID
}

resource "aws_api_gateway_integration" "post_bookmark_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.post_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_bookmark.invoke_arn
}

# [POST] /reviews
resource "aws_api_gateway_method" "post_review" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"  # 인증 방식 설정
  authorizer_id = "s66h90"  # 생성된 Cognito 권한 부여자 ID
}

resource "aws_api_gateway_integration" "post_review_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.post_review.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_review.invoke_arn
}

# [GET] /reviews
resource "aws_api_gateway_method" "get_reviews" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"  # 인증 방식 설정
  authorizer_id = "s66h90"  # 생성된 Cognito 권한 부여자 ID
}

resource "aws_api_gateway_integration" "get_reviews_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.get_reviews.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_reviews.invoke_arn
}

# 5. Lambda 호출 권한
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = toset(["get_restaurants", "post_bookmark", "post_review", "get_reviews"])
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.map_api.execution_arn}/*/*"
}

# 6. 배포 및 스테이지
resource "aws_api_gateway_deployment" "map_deploy" {
    rest_api_id = aws_api_gateway_rest_api.map_api.id

  # API Gateway와 관련된 모든 설정 파일들의 해시값을 감시합니다.
  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.restaurants.id,
        aws_api_gateway_resource.bookmarks.id,
        aws_api_gateway_resource.reviews.id,
        aws_api_gateway_method.get_restaurants.id,
        aws_api_gateway_method.post_bookmark.id,
        aws_api_gateway_method.post_review.id,
        aws_api_gateway_integration.get_restaurants_int.id,
        aws_api_gateway_integration.post_bookmark_int.id,
        aws_api_gateway_integration.post_review_int.id,
        aws_api_gateway_integration.get_reviews_int.id,
    ]))
  }
        
  depends_on = [
    aws_api_gateway_integration.get_restaurants_int,
    aws_api_gateway_integration.post_bookmark_int,
    aws_api_gateway_integration.post_review_int,
    aws_api_gateway_integration.get_reviews_int
  ]
  
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.map_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  stage_name    = "prod"
}

# 출력값: API 엔드포인트 주소 확인용
output "base_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}