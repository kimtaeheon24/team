# 1. 람다용 기본 역할 (Assume Role)
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. 다이나모DB 3개 테이블에 대한 상세 권한 (Policy)
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.project_name}-dynamodb-access"
  description = "Allow Lambda to access restaurants, reviews, and bookmarks tables"

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
        # [핵심] 우리가 만든 3개 테이블의 ARN을 리스트로 묶어줍니다.
        Resource = [
          aws_dynamodb_table.restaurants.arn,
          aws_dynamodb_table.reviews.arn,
          aws_dynamodb_table.bookmarks.arn,
          "${aws_dynamodb_table.reviews.arn}/index/*",   # 인덱스 접근용
          "${aws_dynamodb_table.bookmarks.arn}/index/*" # 인덱스 접근용
        ]
      }
    ]
  })
}

# 3. 역할에 정책 연결 (Attachment)
resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# 4. 로그 기록을 위한 기본 권한 추가
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
