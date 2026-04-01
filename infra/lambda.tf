# 소스 코드 압축
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda"
  output_path = "${path.module}/files/lambda.zip"
}

# 람다 함수 목록 (반복문 사용으로 코드 단축)
locals {
  functions = ["get_restaurants", "get_reviews", "post_review", "post_bookmark"]
}

resource "aws_lambda_function" "map_api" {
  for_each      = toset(local.functions)
  function_name = "${var.project_name}-${each.key}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "${each.key}.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.map_data.name }
RESTAURANT_TABLE = aws_dynamodb_table.restaurants.name
    REVIEW_TABLE     = aws_dynamodb_table.reviews.name
    BOOKMARK_TABLE   = aws_dynamodb_table.bookmarks.name
  }
}
