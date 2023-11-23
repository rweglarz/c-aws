provider "aws" {
  region = var.region
  alias   = "network"
  profile = "my-network"
}

provider "aws" {
  region = var.region
  alias   = "account1"
  profile = "my-account1"
}

# provider "aws" {
#   region = var.region
#   alias   = "sub2"
#   profile = "my-sub2"
# }

terraform {
  required_version = ">= 1.6"
}

data "aws_ami" "ubuntu" {
  provider = aws.network

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


resource "aws_ec2_managed_prefix_list" "mgmt_ips" {
  provider = aws.network

  name           = "${var.name} permitted incoming IPs"
  address_family = "IPv4"
  max_entries    = 20

  dynamic "entry" {
    for_each = var.mgmt_ips
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

