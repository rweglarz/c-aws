provider "aws" {
  region  = var.region
  profile = "cngfw"
}

terraform {
  required_providers {
    cloudngfwaws = {
      source = "PaloAltoNetworks/cloudngfwaws"
      version = "2.0.11"
    }
  }
}

provider "cloudngfwaws" {
  json_config_file = "cloudngfwaws_creds.json"
  profile = "cngfw"

  region = var.region
  host   = "api.${var.region}.aws.cloudngfw.paloaltonetworks.com"
}

data "aws_ami" "latest_ecs" {
  most_recent = true
  owners = ["591542846629"] # AWS

  filter {
      name   = "name"
      values = ["*amazon-ecs-optimized"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}


output "region" {
  value = var.region
}

