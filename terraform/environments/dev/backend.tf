terraform {
  backend "s3" {
    bucket         = "notes-crud-tfstate-94b74612bcff8945"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}