# 1. 사용할 람다 함수 이름들을 정의 (노션 명세와 일치)
locals {
  lambda_names = ["post_bookmark", "get_restaurants", "post_review", "get_reviews"]
}

# 2. 파이썬 소스 코드를 자동으로 .zip으로 압축
data "archive_file" "lambda_zip" {
  for_each    = toset(local.lambda_names)
  type        = "zip"
  source_file = "${path.module}/../src/lambda/${each.key}.py"
  output_path = "${path.module}/../src/lambda/${each.key}.zip"
}

# 3. 람다 함수 생성
resource "aws_lambda_function" "functions" {
  for_each      = toset(local.lambda_names)
  function_name = each.key
  
  # 같은 폴더의 iam.tf에서 정의한 역할을 참조
  role          = aws_iam_role.lambda_role.arn 
  
  handler       = "${each.key}.lambda_handler"
  runtime       = "python3.9"

  # 위에서 압축한 파일을 사용
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  # 다이나모DB 테이블명을 환경변수로 전달
  environment {
    variables = {
      RESTAURANT_TABLE = aws_dynamodb_table.restaurants.name
      BOOKMARK_TABLE   = aws_dynamodb_table.bookmarks.name
      REVIEW_TABLE     = aws_dynamodb_table.reviews.name
    }
  }
}
