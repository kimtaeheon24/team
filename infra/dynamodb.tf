# 1. 맛집 정보 테이블
resource "aws_dynamodb_table" "restaurants" {
  name           = "${var.project_name}-restaurants"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "place_id"

  attribute {
    name = "place_id"
    type = "S"
  }
}

# 2. 리뷰 테이블
resource "aws_dynamodb_table" "reviews" {
  name           = "${var.project_name}-reviews"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "place_id"  # 어떤 장소의 리뷰인지
  range_key      = "timestamp" # 작성 시간 순 정렬

  attribute { name = "place_id";  type = "S" }
  attribute { name = "timestamp"; type = "S" }
}

# 3. 찜(즐겨찾기) 테이블
resource "aws_dynamodb_table" "bookmarks" {
  name           = "${var.project_name}-bookmarks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"   # 어떤 유저가
  range_key      = "place_id"  # 어떤 장소를 찜했나

  attribute { name = "user_id";  type = "S" }
  attribute { name = "place_id"; type = "S" }
}
