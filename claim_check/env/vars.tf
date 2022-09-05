
variable "region" {
    description = "AWS Region to deploy to"
    type = string
    # default ="us-west-2"
}

variable "alias" {
    description = "Alias for provider"
    type = string
}

variable "app_env" {
    description = "Common prefix for Terraform created resources"
    type = string
    default = "claim-check"
}
