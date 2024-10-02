provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"
}

# provider "scm" {
#   host          = "api.strata.paloaltonetworks.com"
#   client_id     = "your-id@12345"
#   client_secret = "secret"
#   scope         = "tsg_id:12345"
# }

terraform {
  required_version = ">= 1.6"
  required_providers {
    # scm = {
    #   source  = "paloaltonetworks/scm"
    #   version = "0.9.2"
    # }
  }
}


module "pl-mgmt_ips" {
  source = "../modules/prefix_list"
  name = "${var.name}-mgmt-ips"
  ips = var.mgmt_ips
}

// populate prefix list to allow inbound to panorama
resource "aws_ec2_managed_prefix_list_entry" "sec_natgw" {
  for_each       = module.vpc-sec.nat_gateways
  cidr           = "${each.value.public_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = var.name
}
