remote_state {
  backend = "s3"
  config = {
    bucket = "bento-tfstates"
    key = "${path_relative_to_include()}.tfstate"
    region = "ap-northeast-1"
    profile = "default"
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
  profile = "default"
}
provider "aws" {
    alias = "virginia"
    region = "us-east-1"
    profile = "default"
}
locals {
  project_name = "bento"
  project_key = "${dirname(path_relative_to_include())}-bento"
}
EOF
}
