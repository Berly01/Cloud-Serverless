# Backend Configuration for Remote State (S3)

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "bpm-monitoring/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
