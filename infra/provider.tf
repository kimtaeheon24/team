# 1. 테라폼 백엔드 및 프로바이더 설정
terraform {
  # (중요) 이 부분이 S3 금고를 사용하는 설정입니다.
  backend "s3" {
    bucket         = "map-project-tfstate"      # 아까 콘솔에서 만든 버킷 이름
    key            = "infra/terraform.tfstate"  # 금고 안의 파일 경로
    region         = "ap-northeast-2"
    encrypt        = true
    # dynamodb_table = "terraform-lock"         # 나중에 잠금 기능 쓸 때 주석 해제!
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# 2. AWS 리전 설정
provider "aws" {
  region = "ap-northeast-2"
}
