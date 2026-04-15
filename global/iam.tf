# 1. 사용자 리스트 정의
variable "team_names" {
  type    = list(string)
  default = ["josh", "jenny", "tina", "sam"]
}

# 2. IAM 사용자 및 로그인 프로필 생성
resource "aws_iam_user" "team" {
  for_each = toset(var.team_names)
  name     = each.value
  path     = "/system/"
}

resource "aws_iam_user_login_profile" "team_login" {
  for_each                = aws_iam_user.team
  user                    = each.value.name
  password_length         = 12
  password_reset_required = true
}

# 3. 그룹 설정
resource "aws_iam_group" "admins" {
  name = "Infrastructure-Admins"
}

resource "aws_iam_group" "developers" {
  name = "Project-Developers"
}

# 4. 그룹별 정책 연결
# 관리자 그룹 권한
resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 개발자 그룹도 임시로 관리자 권한 부여
resource "aws_iam_group_policy_attachment" "dev_admin_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 비밀번호 변경 권한
resource "aws_iam_group_policy_attachment" "dev_change_password" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

# 5. 사용자 그룹 멤버십 설정
resource "aws_iam_user_group_membership" "josh_membership" {
  user   = "josh"
  groups = [aws_iam_group.admins.name]
}

resource "aws_iam_user_group_membership" "team_membership" {
  for_each = toset(["jenny", "tina", "sam"])
  user     = each.value
  groups   = [aws_iam_group.developers.name]
}

# 6. Lambda 실행 역할(Role) 생성
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

# 7. 결과 출력
output "initial_passwords" {
  value = {
    for name, profile in aws_iam_user_login_profile.team_login :
    name => profile.password
  }
  sensitive = true
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}