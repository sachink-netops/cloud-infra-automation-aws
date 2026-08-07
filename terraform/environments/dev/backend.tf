terraform {
  backend "s3" {
    bucket         = "<your-s3-bucket>"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "<your-dynamodb-table>"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
