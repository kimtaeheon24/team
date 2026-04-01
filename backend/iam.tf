# 1. 람다용 IAM 역할(Role) 생성
resource "aws_iam_role" "lambda_role" {
  name = "map_project_lambda_role"

  # 이 역할은 '람다 서비스'가 사용할 수 있도록 허용합니다.
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

# 2. DynamoDB 모든 권한 부여 (연습용 Full Access)
resource "aws_iam_role_policy_attachment" "lambda_dynamo_full" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# 3. 로그 생성을 위한 기본 실행 권한 (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------
# [추가 체크] 만약 나중에 API Gateway가 람다를 직접 호출할 때 
# 권한이 필요할 수 있으나, 보통은 lambda_permission에서 처리하므로 
# 위 3개만으로도 DB 접근은 충분합니다!
# ---------------------------------------------------------