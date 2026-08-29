terraform {
  backend "s3" {
    key          = "aliencommons/stg/opentofu.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
