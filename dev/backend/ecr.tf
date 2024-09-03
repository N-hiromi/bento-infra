resource "aws_ecr_repository" "api" {
  name = "${local.project_key}-api-repository"
}

resource "aws_ecr_repository" "worker" {
  name = "${local.project_key}-worker-repository"
}

resource "aws_ecr_repository" "batch" {
  name = "${local.project_key}-batch-repository"
}

resource "aws_ecr_repository" "ai" {
  name = "${local.project_key}-ai-repository"
}