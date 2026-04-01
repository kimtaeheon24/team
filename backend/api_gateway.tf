# 1. API Gateway 생성
resource "aws_api_gateway_rest_api" "map_api" {
  name = "MapProjectAPI"
}

# 2. 리소스(Path) 생성: /restaurants, /bookmarks, /reviews
resource "aws_api_gateway_resource" "restaurants" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "restaurants"
}

resource "aws_api_gateway_resource" "bookmarks" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "bookmarks"
}

resource "aws_api_gateway_resource" "reviews" {
  rest_api_id = aws_api_gateway_rest_api.map_api.id
  parent_id   = aws_api_gateway_rest_api.map_api.root_resource_id
  path_part   = "reviews"
}

# ---------------------------------------------------------
# 3. 메서드(Method) 및 인티그레이션(Integration) 설정
# ---------------------------------------------------------

# (1) GET /restaurants -> get_restaurants 람다
resource "aws_api_gateway_method" "get_restaurants_method" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.restaurants.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_restaurants_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.restaurants.id
  http_method             = aws_api_gateway_method.get_restaurants_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_functions["get_restaurants"].invoke_arn
}

# (2) POST /bookmarks -> post_bookmark 람다
resource "aws_api_gateway_method" "post_bookmark_method" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "POST"
  authorization = "NONE" # 나중에 Cognito 연동 시 수정
}

resource "aws_api_gateway_integration" "post_bookmark_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.post_bookmark_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_functions["post_bookmark"].invoke_arn
}

# (3) POST /reviews -> post_review 람다
resource "aws_api_gateway_method" "post_review_method" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_review_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.post_review_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_functions["post_review"].invoke_arn
}

# (4) GET /reviews -> get_reviews 람다
resource "aws_api_gateway_method" "get_reviews_method" {
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_reviews_int" {
  rest_api_id             = aws_api_gateway_rest_api.map_api.id
  resource_id             = aws_api_gateway_resource.reviews.id
  http_method             = aws_api_gateway_method.get_reviews_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.map_functions["get_reviews"].invoke_arn
}

# 4. API 배포(Deployment) - 이걸 해야 실제 주소가 생깁니다.
resource "aws_api_gateway_deployment" "map_deploy" {
  depends_on = [
    aws_api_gateway_integration.get_restaurants_int,
    aws_api_gateway_integration.post_bookmark_int,
    aws_api_gateway_integration.post_review_int,
    aws_api_gateway_integration.get_reviews_int
  ]
  rest_api_id = aws_api_gateway_rest_api.map_api.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.map_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.map_api.id
  stage_name    = "dev"
}