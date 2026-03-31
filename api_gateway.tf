# 1. API Gateway 생성
resource "aws_api_gateway_rest_api" "map_api" {
  name        = "MapProjectAPI"
  description = "Restaurant Map Service API with CORS"
}

# 2. 리소스 생성 (경로)
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

# 3. CORS 설정을 위한 재사용 모듈 (공통 설정)
# 각 리소스마다 OPTIONS 메서드를 추가하여 브라우저의 사전 검사를 통과시킵니다.
module "cors" {
  source = "github.com/squidfunk/terraform-aws-api-gateway-enable-cors"
  
  for_each = {
    "res" : aws_api_gateway_resource.restaurants.id,
    "book" : aws_api_gateway_resource.bookmarks.id,
    "rev" : aws_api_gateway_resource.reviews.id
  }

  api_id          = aws_api_gateway_rest_api.map_api.id
  api_resource_id = each.value
}

# 4. 개별 메서드 및 람다 통합

# [GET] /restaurants
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
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_restaurants.invoke_arn
}

# [POST] /bookmarks
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
  uri                     = aws_lambda_function.post_bookmark.invoke_arn
}

# [POST] /reviews
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
  uri                     = aws_lambda_function.post_review.invoke_arn
}

# [GET] /reviews
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
  rest_api_id = aws_api_gateway_rest_api.map_api.id
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