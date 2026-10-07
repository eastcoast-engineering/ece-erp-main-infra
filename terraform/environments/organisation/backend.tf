terraform {
  backend "s3" {
    bucket       = "ece-tfstate-058755926944"
    key          = "infra-core/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
