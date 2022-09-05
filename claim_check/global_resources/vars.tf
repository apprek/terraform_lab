
variable "app_env" {
    description = "Common prefix for Terraform created resources"
    type = string
    default = "claim-check"
}

variable "region" {
    description = "AWS Region"
    type = string
    default = "us-east-1"
}