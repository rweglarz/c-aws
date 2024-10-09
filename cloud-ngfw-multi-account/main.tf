provider "aws" {
  region  = var.region
  profile = "default"
}

provider "aws" {
  region  = var.region
  alias   = "my-account1"
  profile = "my-account1"
}

provider "aws" {
  region  = var.region
  alias   = "my-account2"
  profile = "my-account2"
}


terraform {
  required_providers {
    cloudngfwaws = {
      source = "PaloAltoNetworks/cloudngfwaws"
      version = "~> 2.0.20"
    }
  }
}

provider "cloudngfwaws" {
  json_config_file = "cloudngfwaws_creds.json"
  profile = "default"

  region = var.region
  host   = "api.${var.region}.aws.cloudngfw.paloaltonetworks.com"
  sync_mode = true
}
