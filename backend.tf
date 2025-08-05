terraform {
  backend "s3" {
    bucket         = "dev-terraform-state-prod"
    key            = "modular-infra/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
