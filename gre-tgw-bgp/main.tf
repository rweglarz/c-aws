provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"
}

terraform {
  required_version = ">= 1.8"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
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

resource "aws_ec2_managed_prefix_list_entry" "fws" {
  provider = aws.eu-central-1
  for_each = {
    fw1 = module.fw1.mgmt_public_ip
    fw2 = module.fw2.mgmt_public_ip
  }
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = var.name
}
