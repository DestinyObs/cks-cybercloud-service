terraform {
  backend "s3" {
    bucket         = "naas-prod-terraform-state-staging"
    key            = "staging/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
      }
}
