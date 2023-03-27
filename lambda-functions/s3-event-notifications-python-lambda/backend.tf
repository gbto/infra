terraform {
  backend "s3" {
    bucket                  = "gbto-tfstates-dev"
    key                     = "terraform.tfstate"
    workspace_key_prefix    = "lambda-s3-notifications"
    region                  = "eu-west-1"
    encrypt                 = true
  }
}
