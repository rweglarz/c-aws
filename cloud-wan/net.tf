module "vpc_eu_central" {
  source = "../modules/vpc"
  providers = { aws = aws.eu-central-1 }

  for_each = {
    dev = {
      cidr = local.cidr.dev_eu_central
    }
    prod = {
      cidr = local.cidr.prod_eu_central
    }
    security = {
      cidr = local.cidr.security_eu_central
      routing_scenario = 7
    }
  }

  name = "${var.name}-${each.key}-eu-central"

  cidr_block              = each.value.cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips.eu-central-1
  deploy_igw              = true

  routing_scenario = try(each.value.routing_scenario, 6)

  connect_cwan     = true
  core_network_id  = aws_networkmanager_core_network.this.id
  core_network_arn = aws_networkmanager_core_network.this.arn

  subnets = {
    "corea-a"    : { "idx" : 0, "zone" : "eu-central-1a" },
    "workload-a" : { "idx" : 1, "zone" : "eu-central-1a" },
  }
  tags = {
    env = each.key
  }
  depends_on = [ 
    aws_networkmanager_core_network_policy_attachment.this
  ]
}


module "vpc_eu_west" {
  source = "../modules/vpc"
  providers = { aws = aws.eu-west-1 }

  for_each = {
    dev = {
      cidr = local.cidr.dev_eu_west
    }
    prod = {
      cidr = local.cidr.prod_eu_west
    }
    security = {
      cidr = local.cidr.security_eu_west
      routing_scenario = 7
    }
  }

  name = "${var.name}-${each.key}-eu-west"

  cidr_block              = each.value.cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips.eu-west-1
  deploy_igw              = true

  routing_scenario = try(each.value.routing_scenario, 6)

  connect_cwan     = true
  core_network_id  = aws_networkmanager_core_network.this.id
  core_network_arn = aws_networkmanager_core_network.this.arn

  subnets = {
    "corea-a"    : { "idx" : 0, "zone" : "eu-west-1a" },
    "workload-a" : { "idx" : 1, "zone" : "eu-west-1a" },
  }
  tags = {
    env = each.key
  }
  depends_on = [ 
    aws_networkmanager_core_network_policy_attachment.this
  ]
}


module "vpc_us_east" {
  source = "../modules/vpc"
  providers = { aws = aws.us-east-1 }

  for_each = {
    dev = {
      cidr = local.cidr.dev_us_east
    }
    prod = {
      cidr = local.cidr.prod_us_east
    }
    security = {
      cidr = local.cidr.security_us_east
      routing_scenario = 7
    }
  }

  name = "${var.name}-${each.key}-us-east"

  cidr_block              = each.value.cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips.us-east-1
  deploy_igw              = true

  routing_scenario = try(each.value.routing_scenario, 6)

  connect_cwan     = true
  core_network_id  = aws_networkmanager_core_network.this.id
  core_network_arn = aws_networkmanager_core_network.this.arn

  subnets = {
    "corea-a"    : { "idx" : 0, "zone" : "us-east-1a" },
    "workload-a" : { "idx" : 1, "zone" : "us-east-1a" },
  }
  tags = {
    env = each.key
  }
  depends_on = [ 
    aws_networkmanager_core_network_policy_attachment.this
  ]
}


resource "aws_route" "sec_vpc_us_east" {
  for_each = { for k, v in module.vpc_us_east.security.subnets: k=>v if strcontains(k, "corea-") }
  provider = aws.us-east-1

  route_table_id         = module.vpc_us_east.security.customizable_route_tables.rs7-corea[each.value.availability_zone]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.vms_us_east.security.network_interface_id
} 

resource "aws_route" "sec_vpc_eu_west" {
  for_each = { for k, v in module.vpc_eu_west.security.subnets: k=>v if strcontains(k, "corea-") }
  provider = aws.eu-west-1

  route_table_id         = module.vpc_eu_west.security.customizable_route_tables.rs7-corea[each.value.availability_zone]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.vms_eu_west.security.network_interface_id
} 

resource "aws_route" "sec_vpc_eu_central" {
  for_each = { for k, v in module.vpc_eu_central.security.subnets: k=>v if strcontains(k, "corea-") }
  provider = aws.eu-central-1

  route_table_id         = module.vpc_eu_central.security.customizable_route_tables.rs7-corea[each.value.availability_zone]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.vms_eu_central.security.network_interface_id
} 
