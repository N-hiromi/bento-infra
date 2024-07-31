resource "aws_ecr_repository" "api" {
  name = "${local.project_key}-api"
}

resource "aws_ecr_repository" "worker" {
  name = "${local.project_key}-worker"
}

resource "aws_ecr_repository" "batch" {
  name = "${local.project_key}-batch"
}