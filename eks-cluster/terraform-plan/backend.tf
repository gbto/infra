terraform {
  backend "s3" {
    bucket                  = "gbto-tfstates-sbx"
    key                     = "gbto-eks-sbx.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "default"
    encrypt                 = true
  }
}
