terraform {
  backend "s3" {
    bucket                  = "gbto-tfstates-sbx"
    key                     = "gbto-ecs-mwaa-redshit-sbx.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "default"
    encrypt                 = true
  }
}
