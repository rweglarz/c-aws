terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.region
}

resource "aws_ec2_managed_prefix_list" "mgmt_ips" {
  name           = "List of public permitted incoming IPs"
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

