# 1. 사용자 리스트 정의
variable "team_names" {
  type    = list(string)
  default = ["josh", "jenny", "tina", "sam"]
}

# 2. IAM 사용자 생성
resource "aws_iam_user" "team" {
  for_each = toset(var.team_names)
  name     = each.value
  path     = "/system/"
}

# 로그인 프로필
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

resource "aws_iam_group" "cicd" {
  name = "CI-CD-Admins"
}

# 4. 정책 연결

# Admin (josh)
resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CI/CD (tina)
resource "aws_iam_group_policy_attachment" "cicd_attach" {
  group      = aws_iam_group.cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Developers (jenny, sam) → 제한 권한
resource "aws_iam_group_policy_attachment" "dev_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "dev_lambda" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "dev_dynamodb" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "dev_apigw" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

resource "aws_iam_group_policy_attachment" "dev_cloudwatch" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "dev_change_password" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

# 5. 사용자 그룹 매핑

# josh → admin
resource "aws_iam_user_group_membership" "josh_membership" {
  user   = "josh"
  groups = [aws_iam_group.admins.name]
}

# tina → cicd
resource "aws_iam_user_group_membership" "tina_membership" {
  user   = "tina"
  groups = [aws_iam_group.cicd.name]
}

# jenny, sam → developers
resource "aws_iam_user_group_membership" "team_membership" {
  for_each = toset(["jenny", "sam"])
  user     = each.value
  groups   = [aws_iam_group.developers.name]
}

# 6. 출력
output "initial_passwords" {
  value = {
    for name, profile in aws_iam_user_login_profile.team_login :
    name => profile.password
  }
  sensitive = true
}