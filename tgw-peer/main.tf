provider "aws" {
  region = var.region
}
provider "aws" {
  region = var.peer-region
  alias = "peer"
}

data "terraform_remote_state" "mgmt" {
  backend = "local"
  config = {
    path = "../mgmt/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    panos = {
      source  = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}

data "terraform_remote_state" "tgw" {
  backend = "local"
  config = {
    path = "../tgw/terraform.tfstate"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-${var.ubuntu_version}-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

