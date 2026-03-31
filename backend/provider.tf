terraform {
  backend "s3" {
    bucket  = "taeheon-jennie-tfstate-2026"
    key     = "terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" { region = "ap-northeast-2" } 
