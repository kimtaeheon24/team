# 1. 함수 리스트 정의
locals {
  functions = ["post_bookmark", "get_restaurants", "post_review", "get_reviews"]
}

# 2. 람다 함수 생성 (CORS 대응 로직이 포함된 코드가 dummy.zip에 있어야 함)
resource "aws_lambda_function" "map_functions" {
  for_each      = toset(local.functions)
  function_name = each.key
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler" # 파일명이 index.py 일 경우
  runtime       = "python3.12"

  # 실제 코드가 담긴 압축 파일
  filename         = "dummy.zip" 
  source_code_hash = filebase64sha256("dummy.zip") # 코드 변경 시 자동 감지

  environment {
    variables = {
      STAGE = "dev"
    }
  }
}

# 3. 모든 람다 함수에 대해 API Gateway 호출 허용
resource "aws_lambda_permission" "api_gw" {
  for_each      = toset(local.functions)
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.map_functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # 내 API Gateway에서 오는 요청만 수락
  source_arn = "${aws_api_gateway_rest_api.map_api.execution_arn}/*/*"
}