terraform {
  backend "s3" {
    bucket                  = "gbto-tfstates-sbx"
    key                     = "gbto-lambda-cloudwatch-redshift-procedure-dev.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "default"
    encrypt                 = true
  }
}
