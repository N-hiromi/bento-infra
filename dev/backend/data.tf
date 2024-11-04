################# data #################
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.project_key]
  }
}

data "aws_security_group" "alb" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-alb-sg"]
  }
}

data "aws_security_group" "api_sg" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-api-sg"]
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

data "aws_key_pair" "key" {
  key_name = local.project_key
}
