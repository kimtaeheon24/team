resource "aws_iam_role" "lambda_exec_role" {
  name = "map-project-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_full" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 1. 사용할 람다 함수 이름들을 정의
locals {
  lambda_names = ["post_bookmark", "get_restaurants", "post_review", "get_reviews", "get_my_bookmarks"]
}

# 2. [Layer용] 공통 유틸리티 폴더 압축
data "archive_file" "common_layer" {
  type = "zip"
  # 수현님의 폴더 구조에 맞게 경로 수정: ../src/layers/common
  source_dir  = "${path.module}/../src/layers/common"
  output_path = "${path.module}/common_layer.zip"
}

# 3. [Layer용] Lambda Layer 리소스 생성
resource "aws_lambda_layer_version" "common_utils" {
  filename            = data.archive_file.common_layer.output_path
  layer_name          = "common_utils_layer"
  compatible_runtimes = ["python3.9"]
  source_code_hash    = data.archive_file.common_layer.output_base64sha256
}

# 4. [Lambda용] 각 파이썬 소스 코드를 .zip으로 압축
data "archive_file" "lambda_zip" {
  for_each    = toset(local.lambda_names)
  type        = "zip"
  source_file = "${path.module}/../src/lambda/${each.key}.py"
  output_path = "${path.module}/../src/lambda/${each.key}.zip"
}

# 5. 람다 함수 생성 (통합 버전)
resource "aws_lambda_function" "functions" {
  for_each      = toset(local.lambda_names)
  function_name = each.key

  role    = aws_iam_role.lambda_exec_role.arn
  handler = "${each.key}.lambda_handler"
  runtime = "python3.9"

  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  # [핵심] 모든 함수에 레이어를 자동으로 연결합니다.
  layers = [aws_lambda_layer_version.common_utils.arn]

  environment {
    variables = {
      RESTAURANT_TABLE = aws_dynamodb_table.restaurants.name
      BOOKMARK_TABLE   = aws_dynamodb_table.bookmarks.name
      REVIEW_TABLE     = aws_dynamodb_table.reviews.name
    }
  }
}