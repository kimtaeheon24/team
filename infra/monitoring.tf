# -------------------------------
# Lambda: post_review 에러 알람
# -------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors_post_review" {
  alarm_name          = "lambda-post-review-errors"
  alarm_description   = "post_review Lambda error alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  period      = 300
  statistic   = "Sum"

  dimensions = {
    FunctionName = "post_review"
  }
}

# -------------------------------
# Lambda: post_review 실행시간 알람
# -------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_duration_post_review" {
  alarm_name          = "lambda-post-review-duration"
  alarm_description   = "post_review Lambda duration alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 3000

  namespace   = "AWS/Lambda"
  metric_name = "Duration"
  period      = 300
  statistic   = "Average"

  dimensions = {
    FunctionName = "post_review"
  }
}

# -------------------------------
# API Gateway 4xx 알람
# -------------------------------
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx" {
  alarm_name          = "api-gateway-4xx"
  alarm_description   = "API Gateway 4xx alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5

  namespace   = "AWS/ApiGateway"
  metric_name = "4xx"
  period      = 300
  statistic   = "Sum"

  dimensions = {
    ApiId = aws_apigatewayv2_api.map_api.id
  }
}

# -------------------------------
# API Gateway 5xx 알람
# -------------------------------
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "api-gateway-5xx"
  alarm_description   = "API Gateway 5xx alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1

  namespace   = "AWS/ApiGateway"
  metric_name = "5xx"
  period      = 300
  statistic   = "Sum"

  dimensions = {
    ApiId = aws_apigatewayv2_api.map_api.id
  }
}