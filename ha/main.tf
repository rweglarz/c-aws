provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"
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
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


// populate prefix list to allow inbound to panorama
module "pl-ha1z_a" {
  providers = { aws = aws.eu-central-1 }
  source    = "../modules/prefix_list_entry"

  for_each       = module.fw-ha1z_a.public_ips
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-ha1z-a"
}
module "pl-ha1z_b" {
  providers = { aws = aws.eu-central-1 }
  source    = "../modules/prefix_list_entry"

  for_each       = module.fw-ha1z_b.public_ips
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-ha1z-b"
}

module "pl-ha2z_a" {
  providers = { aws = aws.eu-central-1 }
  source    = "../modules/prefix_list_entry"

  for_each       = module.fw-ha2z_a.public_ips
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-ha2z-a"
}
module "pl-ha2z_b" {
  providers = { aws = aws.eu-central-1 }
  source    = "../modules/prefix_list_entry"

  for_each       = module.fw-ha2z_b.public_ips
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-ha2z-b"
}
