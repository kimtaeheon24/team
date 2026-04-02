# 1. API 게이트웨이 생성
resource "aws_api_gateway_rest_api" "map_api" {
  name        = "MapProject-API"
  description = "맛집 지도 프로젝트 통합 API"
}

# 2. 리소스 정의 (경로 만들기: /restaurants, /reviews, /bookmarks)
resource "aws_api_gateway_resource" "res" {
  for_each    = toset(["restaurants", "reviews", "bookmarks"])
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = each.key
}

# 3. CORS 설정 (모든 리소스에 대해 브라우저 허용)
module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  for_each        = aws_api_gateway_resource.res
  api_id          = aws_api_gateway_rest_api.map_api.id
  api_resource_id = each.value.id
}

# 4. API 메서드 및 람다 통합 (노션 설계 반영)
# GET /restaurants
resource "aws_api_gateway_method" "get_restaurants" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.res["restaurants"].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_restaurants_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.res["restaurants"].id
  http_method             = aws_api_gateway_method.get_restaurants.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions["get_restaurants"].invoke_arn
}

# GET /reviews
resource "aws_api_gateway_method" "get_reviews" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.res["reviews"].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_reviews_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.res["reviews"].id
  http_method             = aws_api_gateway_method.get_reviews.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions["get_reviews"].invoke_arn
}

# POST /reviews
resource "aws_api_gateway_method" "post_review" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.res["reviews"].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_review_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.res["reviews"].id
  http_method             = aws_api_gateway_method.post_review.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions["post_review"].invoke_arn
}

# POST /bookmarks
resource "aws_api_gateway_method" "post_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.res["bookmarks"].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_bookmark_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.res["bookmarks"].id
  http_method             = aws_api_gateway_method.post_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions["post_bookmark"].invoke_arn
}

# 5. 람다 호출 권한 (API GW -> Lambda)
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = aws_lambda_function.functions
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.map_api.execution_arn}/*/*"
}

# 6. 배포 및 스테이지 설정
resource "aws_api_gateway_deployment" "dev" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id

  # 모든 메서드 연결이 완료된 후 배포
  depends_on = [
    aws_api_gateway_integration.get_restaurants_int,
    aws_api_gateway_integration.get_reviews_int,
    aws_api_gateway_integration.post_review_int,
    aws_api_gateway_integration.post_bookmark_int
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.dev.id
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  stage_name    = "dev"
}

# 7. 출력값 (터미널에서 바로 확인 가능)
output "api_url" {
  value = aws_api_gateway_stage.dev.invoke_url
}
