# 1. 람다용 공통 IAM Role (3개 함수가 같이 사용)
resource "aws_iam_role" "lambda_exec_role" {
  name = "map_project_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. DynamoDB 및 CloudWatch 로그 권한 부여
resource "aws_iam_role_policy_attachment" "lambda_dynamo_full" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. 파이썬 파일들을 각각 ZIP으로 압축 (Terraform이 알아서 해줌)
data "archive_file" "get_restaurants_zip" {
  type        = "zip"
  source_file = "${path.module}/get_restaurants.py"
  output_path = "${path.module}/get_restaurants.zip"
}

data "archive_file" "review_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/review_handler.py"
  output_path = "${path.module}/review_handler.zip"
}

data "archive_file" "bookmark_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/bookmark_handler.py"
  output_path = "${path.module}/bookmark_handler.zip"
}

# 4. Lambda 함수 정의 (3개)

# (1) 식당 목록 조회
resource "aws_lambda_function" "get_restaurants" {
  filename         = data.archive_file.get_restaurants_zip.output_path
  function_name    = "getRestaurants"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "get_restaurants.lambda_handler" # 파일명.함수명
  runtime          = "python3.9"
  source_code_hash = data.archive_file.get_restaurants_zip.output_base64sha256
}

# (2) 리뷰 관리
resource "aws_lambda_function" "review_handler" {
  filename         = data.archive_file.review_handler_zip.output_path
  function_name    = "reviewHandler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "review_handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.review_handler_zip.output_base64sha256
}

# (3) 즐겨찾기 관리
resource "aws_lambda_function" "bookmark_handler" {
  filename         = data.archive_file.bookmark_handler_zip.output_path
  function_name    = "bookmarkHandler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "bookmark_handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.bookmark_handler_zip.output_base64sha256
}