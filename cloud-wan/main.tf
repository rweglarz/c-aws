provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

terraform {
  required_version = ">= 1.8"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
    aws = {
      version = "~>5.52"
    }
    google = {
      version = "~>6.10"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "panos_vm_auth_key" "this" {
  hours = 24*30*6

  lifecycle { create_before_destroy = true }
}

