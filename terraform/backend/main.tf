provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project}-tfstate-${var.environment}"
  force_destroy = false

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project}-tflocks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
