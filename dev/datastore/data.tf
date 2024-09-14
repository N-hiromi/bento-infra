data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.project_key]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-public*"]
  }
}

# data "aws_iam_role" "cognito_identity_role" {
#   name = "nnaabbee_tidy_sample_id_pool_role"
# }