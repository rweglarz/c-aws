module "vpc_local" {
  source   = "../modules/vpc"

  name = "${var.name}-parent"

  cidr_block              = cidrsubnet(var.cidr, 2, 1)
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips[var.region]
  deploy_igw              = true
  deploy_natgw            = false
  connect_tgw             = false

  routing_scenario        = 2

  gwlb_service_name       = cloudngfwaws_ngfw.this.endpoint_service_name

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "gwlbe-a"    : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

module "pl_account_1" {
  source   = "../modules/prefix_list"
  providers = { aws = aws.my-account1 }

  name = "${var.name}-account-1"
  ips = var.mgmt_ips
}

module "pl_account_2" {
  source   = "../modules/prefix_list"
  providers = { aws = aws.my-account2 }

  name = "${var.name}-account-2"
  ips = var.mgmt_ips
}

module "vpc_account_1" {
  source   = "../modules/vpc"
  providers = { aws = aws.my-account1 }

  name = "${var.name}-account-1"

  cidr_block              = cidrsubnet(var.cidr, 2, 2)
  public_mgmt_prefix_list = module.pl_account_1.id
  deploy_igw              = true
  deploy_natgw            = false
  connect_tgw             = false

  routing_scenario        = 2

  gwlb_service_name       = cloudngfwaws_ngfw.this.endpoint_service_name

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[1] },
    "gwlbe-a"    : { "idx" : 1, "zone" : var.availability_zones[1] },
  }
}

module "vpc_account_2" {
  source   = "../modules/vpc"
  providers = { aws = aws.my-account2 }

  name = "${var.name}-account-2"

  cidr_block              = cidrsubnet(var.cidr, 2, 3)
  public_mgmt_prefix_list = module.pl_account_2.id
  deploy_igw              = true
  deploy_natgw            = false
  connect_tgw             = false

  routing_scenario        = 2

  gwlb_service_name       = cloudngfwaws_ngfw.this.endpoint_service_name

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[2] },
    "gwlbe-a"    : { "idx" : 1, "zone" : var.availability_zones[2] },
  }
}
