################# data #################
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.project_key]
  }
}

data "aws_subnet_ids" "private_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-private*"]
  }
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-public*"]
  }
}

data "aws_security_group" "mysql" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-mysql-sg"]
  }
}

data "aws_security_group" "bastion" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_key}-bastion-sg"]
  }
}

################# parameter group #################
resource "aws_rds_cluster_parameter_group" "utf8" {
  name   = "${local.project_key}-utf8"
  family = "aurora-mysql5.7"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "5"
  }

  parameter {
    name  = "server_audit_logging"
    value = "1"
  }

  parameter {
    name  = "server_audit_events"
    value = "QUERY"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }
}

################# aurora-subnet #################
resource "aws_db_subnet_group" "default" {
  name       = "${local.project_key}-mysql"
  subnet_ids = data.aws_subnet_ids.private_subnet_ids.ids
  tags = {
    Name = "${local.project_key}-mysql"
  }
}

################# aurora #################
module "rds_aurora" {
  source                              = "terraform-aws-modules/rds-aurora/aws"
  name                                = local.project_key
  engine                              = "aurora-mysql"
  engine_version                      = "5.7.mysql_aurora.2.09.2"
  vpc_id                              = data.aws_vpc.vpc.id
  subnets                             = data.aws_subnet_ids.private_subnet_ids.ids
  db_subnet_group_name                = aws_db_subnet_group.default.name
  database_name                       = local.project_name
  username                            = "master"
  password                            = ""
  create_random_password              = true
  replica_count                       = 1
  instance_type                       = "db.t3.small"
  skip_final_snapshot                 = true
  vpc_security_group_ids              = [data.aws_security_group.mysql.id]
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.utf8.id
  publicly_accessible                 = false
  iam_database_authentication_enabled = false
  snapshot_identifier                 = null
  preferred_backup_window             = "21:00-22:00" # JST 6:00
  backup_retention_period             = 3
  auto_minor_version_upgrade          = true
  preferred_maintenance_window        = "fri:22:00-fri:23:00" # JST 7:00
}

################# s3 #################
module "log" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.project_key}-log"
  acl    = "private"
}



################# key pair #################
module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  key_name   = "${local.project_key}-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbLbdmhxSrHGZdmkonXRsGE7xiYCQcHdMAd//HMJdRU91GUPCe9fzHC1WiWqhWONOANnif+7EKip9xTR9+lDxsVfKVtfOjYPMrM+YzY0X/PY2dnOimxEcbMvwqPJlz1E/IAIiOClOOXRmorQFZ0y6GhJJhW5Vd52LDqPB3cxJ405vOzroekhKXLSbAPnSwHdaGREw+8SwzhpgYm/xkGgE6b15gnq+1eTN0a9Z2fb3Mdq9yTaMsOp3zZ/2DteThYGBNMpEpwjvIpDgJXMm4Yf9YRVt8gbSpfjcc+Dy1QBKirucDEsfTf0s4SRGcsjXIUrhPjh8JG+hcNtuAgdd4Ics/"
}

############### ec2 instance #################
module "ec2_instance_bastion" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "${local.project_key}-bastion"
  ami                         = "ami-052652af12b58691f"
  instance_type               = "t2.micro"
  key_name                    = module.key_pair.key_pair_key_name
  vpc_security_group_ids      = [data.aws_security_group.bastion.id]
  subnet_ids                  = data.aws_subnet_ids.public_subnet_ids.ids
  associate_public_ip_address = true
}
