provider "aws" {
  region = var.aws_region
}

locals {
  project_name = var.project_name
  tags = merge({
    Project = local.project_name,
    Managed = "terraform",
    Environment = var.environment
  }, var.tags)
}
