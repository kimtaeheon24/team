# 1. Restaurants Table
resource "aws_dynamodb_table" "restaurants" {
  name         = "Restaurants"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "place_id"

  attribute {
    name = "place_id"
    type = "S"
  }
}

# 2. Bookmarks Table
resource "aws_dynamodb_table" "bookmarks" {
  name         = "Bookmarks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"  # PK: 사용자 구분
  range_key    = "place_id" # SK: 카카오맵 장소 ID

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "place_id"
    type = "S"
  }
}

# 3. Reviews Table (PK/SK 구조 수정)
resource "aws_dynamodb_table" "reviews" {
  name         = "Reviews"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "place_id"  # PK: 카카오맵 장소 ID (특정 식당의 리뷰를 모으기 위함)
  range_key    = "review_id" # SK: 작성 리뷰 구분 (고유 번호)

  attribute {
    name = "place_id"
    type = "S"
  }

  attribute {
    name = "review_id"
    type = "S"
  }
}