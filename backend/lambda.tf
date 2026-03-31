resource "aws_iam_role" "lambda_role" {
  name = "map_project_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

# resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
# }

# 1. 각 테이블에 대한 세부 권한 정의 (Policy Document)
resource "aws_iam_policy" "lambda_dynamo_restricted" {
  name        = "map_project_dynamo_restricted_policy"
  description = "Allow Lambda to access only specific DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Restaurants 테이블: 조회 및 쓰기 권한
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.restaurants.arn
      },
      {
        # Bookmarks 테이블: 조회 및 쓰기 권한
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.bookmarks.arn
      },
      {
        # Reviews 테이블: 조회 및 쓰기 권한
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.reviews.arn
      }
    ]
  })
}

# 2. 생성한 정책을 기존 람다 역할(Role)에 연결
resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamo_restricted.arn
}

# 1. 식당 조회 (GET)
resource "aws_lambda_function" "get_restaurants" {
  filename      = "get_restaurants.zip"
  function_name = "get_restaurants"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_restaurants.lambda_handler"
  runtime       = "python3.9"
}

# 2. 북마크 저장 (POST)
resource "aws_lambda_function" "post_bookmark" {
  filename      = "post_bookmark.zip"
  function_name = "post_bookmark"
  role          = aws_iam_role.lambda_role.arn
  handler       = "post_bookmark.lambda_handler"
  runtime       = "python3.9"
}

# 3. 리뷰 저장 (POST)
resource "aws_lambda_function" "post_review" {
  filename      = "post_review.zip"
  function_name = "post_review"
  role          = aws_iam_role.lambda_role.arn
  handler       = "post_review.lambda_handler"
  runtime       = "python3.9"
}

# 4. 리뷰 조회 (GET)
resource "aws_lambda_function" "get_reviews" {
  filename      = "get_reviews.zip"
  function_name = "get_reviews"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_reviews.lambda_handler"
  runtime       = "python3.9"
}

# CloudWatch Log Groups (람다별 로그 저장소)
resource "aws_cloudwatch_log_group" "get_restaurants_log" {
  name              = "/aws/lambda/get_restaurants"
  retention_in_days = 7  # 로그 보관 기간 (7일 후 자동 삭제, 비용 절감)
}

resource "aws_cloudwatch_log_group" "post_bookmark_log" {
  name              = "/aws/lambda/post_bookmark"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "post_review_log" {
  name              = "/aws/lambda/post_review"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "get_reviews_log" {
  name              = "/aws/lambda/get_reviews"
  retention_in_days = 7
}

# 람다가 로그를 남길 수 있도록 권한 추가 (IAM Role에 정책 연결)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}