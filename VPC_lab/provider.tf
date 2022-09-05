# provider.tf

provider "aws" {
    region = "us-east-1"
}

terraform {
  required_version = ">= 0.14.9"
  # backend "s3" {}
}