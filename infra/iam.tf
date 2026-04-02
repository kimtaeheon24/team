# 1. 람다 실행 역할
resource "aws_iam_role" "lambda_role" {
  name = "MapProject-Lambda-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. 다이나모DB 및 로그 접근 정책
resource "aws_iam_policy" "lambda_policy" {
  name        = "MapProject-Lambda-Policy"
  description = "Allows access to Restaurants, Bookmarks, and Reviews tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = [
          aws_dynamodb_table.restaurants.arn,
          aws_dynamodb_table.bookmarks.arn,
          aws_dynamodb_table.reviews.arn,
          "${aws_dynamodb_table.reviews.arn}/index/*" # 인덱스 조회용
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 3. 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
