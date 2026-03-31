resource "aws_iam_role" "lambda_role" {
  name = "map_project_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# 람다 함수 (3개)
resource "aws_lambda_function" "get_restaurants" {
  filename      = "get_restaurants.zip"
  function_name = "getRestaurants"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_restaurants.lambda_handler"
  runtime       = "python3.9"
}

resource "aws_lambda_function" "review_handler" {
  filename      = "review_handler.zip"
  function_name = "reviewHandler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "review_handler.lambda_handler"
  runtime       = "python3.9"
}

resource "aws_lambda_function" "bookmark_handler" {
  filename      = "bookmark_handler.zip"
  function_name = "bookmarkHandler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bookmark_handler.lambda_handler"
  runtime       = "python3.9"
}
