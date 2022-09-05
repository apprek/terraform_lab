
# For Global Resources tfstate 
provider "aws" {
    region = "us-east-1"
}

terraform {
  required_version = ">= 0.14.9"

   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    # Replace this with your bucket name!
    bucket               = "claim-check-global"
    key                  = "global_resources_tfstate"
    region               = "us-east-1"
   }
}
