provider "aws" {
  region = var.region
}

data "terraform_remote_state" "mgmt" {
  backend = "local"
  config = {
    path = "../mgmt/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.8"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~>1.11"
    }
    aws = {
      version = "~>5.88"
    }
    google = {
      version = "~>6.8"
    }
  }
}
