terraform {
  required_version = ">= 1.2.0"

   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
 
    backend "s3" {
      # Replace this with your bucket name!
      bucket               = "claim-check-env"
      key                  = "terraform-states-lock-table"
      region               = "us-east-1"
    }
}

# data "terraform_remote_state" "info" {
#   backend = "s3"
#   config = {
#     # Replace this with your bucket name!
#     bucket = "claim-check-global"
#     key    = "global_resources_tfstate"
#     region = "us-east-1"
#   }
# }


