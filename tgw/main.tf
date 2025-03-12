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

resource "aws_vpc_ipam" "this" {
  operating_regions {
    region_name = var.region
  }
}

resource "aws_vpc_ipam_pool" "ipv6_private" {
  address_family        = "ipv6"
  publicly_advertisable = false
  ipam_scope_id         = aws_vpc_ipam.this.private_default_scope_id
  locale                = var.region
  allocation_default_netmask_length = 56
}

resource "aws_vpc_ipam_pool" "ipv6_public" {
  address_family        = "ipv6"
  publicly_advertisable = false
  ipam_scope_id         = aws_vpc_ipam.this.public_default_scope_id
  locale                = var.region
  public_ip_source      = "amazon"
  aws_service           = "ec2"
  allocation_default_netmask_length = 56
}

resource "aws_vpc_ipam_pool_cidr" "ipv6_private" {
  ipam_pool_id   = aws_vpc_ipam_pool.ipv6_private.id
  netmask_length = 52
}

resource "aws_vpc_ipam_pool_cidr" "ipv6_public" {
  ipam_pool_id   = aws_vpc_ipam_pool.ipv6_public.id
  netmask_length = 52
}
