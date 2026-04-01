# 1. Restaurants 테이블 (PK: place_id)
resource "aws_dynamodb_table" "restaurants" {
  name           = "Restaurants"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "place_id"

  attribute {
    name = "place_id"
    type = "S"
  }
}

# 2. Bookmarks 테이블 (PK: user_id, SK: place_id)
resource "aws_dynamodb_table" "bookmarks" {
  name           = "Bookmarks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "place_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "place_id"
    type = "S"
  }
}

# 3. Reviews 테이블 (PK: place_id, SK: review_id)
resource "aws_dynamodb_table" "reviews" {
  name           = "Reviews"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "place_id"
  range_key      = "review_id"

  attribute {
    name = "place_id"
    type = "S"
  }
  attribute {
    name = "review_id"
    type = "S"
  }
}
