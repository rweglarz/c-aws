provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    cloudngfwaws = {
      source = "PaloAltoNetworks/cloudngfwaws"
      version = "1.0.8"
    }
  }
}

provider "cloudngfwaws" {
  json_config_file = "cloudngfwaws_creds.json"

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



