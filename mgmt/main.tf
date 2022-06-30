terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

resource "aws_ec2_managed_prefix_list" "mgmt_ips" {
  name           = "${var.name} public permitted incoming IPs"
  address_family = "IPv4"
  max_entries    = 15

  dynamic "entry" {
    for_each = var.mgmt_ips
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

module "pl-eu_west_1-mgmt_ips" {
  source    = "../modules/prefix_list"
  providers = { aws = aws.eu-west-1 }

  name = "${var.name} public permitted incoming IPs"
  ips  = var.mgmt_ips
}

resource "aws_ec2_managed_prefix_list" "csp_nat_ips" {
  name           = "${var.name} csp permitted incoming IPs"
  address_family = "IPv4"
  max_entries    = 15
}

resource "aws_ec2_managed_prefix_list" "tmp_ips" {
  name           = "${var.name} public permitted tmp IPs"
  address_family = "IPv4"
  max_entries    = 15

  dynamic "entry" {
    for_each = var.tmp_ips
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}
