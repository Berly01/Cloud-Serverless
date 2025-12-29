provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "bpm-monitoring"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    }
  }
}
