terraform {
  backend "s3" {
    bucket = "terraform-prefect-state-yarin"
    key    = "terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
    versioning = true
  }
}