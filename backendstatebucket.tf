terraform {
  backend "s3" {
    bucket         = "terraformbackendbucket042022"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "jenkinslock-tf"
  }

}
