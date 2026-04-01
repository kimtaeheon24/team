# 1. API 게이트웨이 생성
resource "aws_api_gateway_rest_api" "map_api" {
  name        = "${var.project_name}-api"
  description = "Map Project API Gateway"
}

# ---------------------------------------------------------
# 2. 리소스(Path) 정의
# ---------------------------------------------------------
resource "aws_api_gateway_resource" "restaurants" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "restaurants"
}

resource "aws_api_gateway_resource" "reviews" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "reviews"
}

resource "aws_api_gateway_resource" "bookmarks" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "bookmarks"
}

# ---------------------------------------------------------
# 3. 메서드 & 통합 (GET /restaurants -> get_restaurants 람다)
# ---------------------------------------------------------
resource "aws_api_gateway_method" "get_restaurants" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.restaurants.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_restaurants_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.restaurants.id
  http_method             = aws_api_gateway_method.get_restaurants.http_method
  integration_http_method = "POST" # 람다 호출은 내부적으로 항상 POST입니다
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_api["get_restaurants"].invoke_arn
}

# ---------------------------------------------------------
# 4. 메서드 & 통합 (GET /reviews -> get_reviews 람다)
# ---------------------------------------------------------
resource "aws_api_gateway_method" "get_reviews" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_reviews_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.get_reviews.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_api["get_reviews"].invoke_arn
}

# ---------------------------------------------------------
# 5. 메서드 & 통합 (POST /reviews -> post_review 람다)
# ---------------------------------------------------------
resource "aws_api_gateway_method" "post_review" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_review_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.post_review.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_api["post_review"].invoke_arn
}

# ---------------------------------------------------------
# 6. 메서드 & 통합 (POST /bookmarks -> post_bookmark 람다)
# ---------------------------------------------------------
resource "aws_api_gateway_method" "post_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_bookmark_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.post_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_api["post_bookmark"].invoke_arn
}

# ---------------------------------------------------------
# 7. 배포 (Deployment) & 스테이지(Stage)
# ---------------------------------------------------------
resource "aws_api_gateway_deployment" "map_api" {
  depends_on  = [
    aws_api_gateway_integration.get_restaurants_int,
    aws_api_gateway_integration.get_reviews_int,
    aws_api_gateway_integration.post_review_int,
    aws_api_gateway_integration.post_bookmark_int
  ]
  rest_api_id = aws_api_gateway_rest_api.map_api.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.map_api.id
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  stage_name    = "dev"
}

# ---------------------------------------------------------
# 8. 람다 호출 권한 부여 (Permission)
# ---------------------------------------------------------
resource "aws_lambda_permission" "api_gw" {
  for_each      = aws_lambda_function.map_api
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.map_api.execution_arn}/*/*"
}
