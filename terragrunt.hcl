remote_state {
  backend = "s3"
  config = {
    bucket = "tidy-tfstates"
    key = "${path_relative_to_include()}.tfstate"
    region = "ap-northeast-1"
    profile = "tidy"
    encrypt = true
  }
}

generate "generated" {
  path = "generated.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {}
  required_version = "1.9.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-1"
  profile = "tidy"
}
provider "aws" {
    alias = "virginia"
    region = "us-east-1"
    profile = "tidy"
}
locals {
  project_name = "tidy"
  project_key = "${dirname(path_relative_to_include())}-tidy"
}
EOF
}
