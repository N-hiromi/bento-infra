################# vpc #################
module "vpc" {
  version = "~> 5.0"
  source                = "terraform-aws-modules/vpc/aws"
  name                  = local.project_key
  cidr                  = "10.0.0.0/16"
  private_subnets       = ["10.0.0.0/19", "10.0.32.0/19"]   # "10.0.64.0/19"
  public_subnets        = ["10.0.96.0/19", "10.0.128.0/19"] # "10.0.160.0/19"
  enable_nat_gateway    = false
  single_nat_gateway    = false
  reuse_nat_ips         = true
  azs                   = ["apne1-az1", "apne1-az2"] # "apne1-az4"
  private_subnet_suffix = "private-subnet"
  public_subnet_suffix  = "public-subnet"
}

################# security-groups #################
module "alb-sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${local.project_key}-alb-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_cidr_blocks = [{
    description = "Allow ingress on port 80 from 0.0.0.0/0"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }]
  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]
}

module "api-sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${local.project_key}-api-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      description              = "from alb"
      from_port                = 80
      to_port                  = 80
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

module "batch-sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${local.project_key}-batch-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      description              = "from alb"
      from_port                = 80
      to_port                  = 80
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

module "worker-sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${local.project_key}-worker-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      description              = "from alb"
      from_port                = 80
      to_port                  = 80
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
