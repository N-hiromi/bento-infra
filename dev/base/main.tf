data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

################# vpc #################
module "vpc" {
  version                 = "~> 5.0"
  source                  = "terraform-aws-modules/vpc/aws"
  name                    = local.project_key
  cidr                    = "10.0.0.0/16"
  public_subnets          = ["10.0.96.0/19", "10.0.128.0/19"] # "10.0.160.0/19"
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  reuse_nat_ips           = true
  azs                     = ["apne1-az1", "apne1-az2"] # "apne1-az4"
  public_subnet_suffix    = "public-subnet"
}

################# security-groups #################
module "alb-sg" {
  version = "5.1.2"
  source  = "terraform-aws-modules/security-group/aws"
  name    = "${local.project_key}-alb-sg"
  vpc_id  = module.vpc.vpc_id
  ingress_with_cidr_blocks = [{
    description = "Allow ingress on port 8080 from 0.0.0.0/0"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    prefix_list_ids = data.aws_ec2_managed_prefix_list.cloudfront.id
  }]
  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]
}

resource "aws_vpc_security_group_ingress_rule" "allow_custom_header_ingress" {
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  security_group_id = module.alb-sg.security_group_id
  description       = "Allow ingress on port 8080 with custom header"
}

module "api-sg" {
  version = "5.1.2"
  source  = "terraform-aws-modules/security-group/aws"
  name    = "${local.project_key}-api-sg"
  vpc_id  = module.vpc.vpc_id
  #   albからのアクセスを許可
  ingress_with_source_security_group_id = [
    {
      description              = "from alb"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "TCP"
      source_security_group_id = module.alb-sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [{
    description = "to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]
}
