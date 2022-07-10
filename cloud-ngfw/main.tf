provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    cloudngfwaws = {
      source = "PaloAltoNetworks/cloudngfwaws"
      version = "1.0.7"
    }
  }
}

provider "cloudngfwaws" {
  json_config_file = "cloudngfwaws_creds.json"
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



