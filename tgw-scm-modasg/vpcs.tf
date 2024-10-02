module "vpc-mgmt" {
  source = "../modules/vpc"

  name = "${var.name}-mgmt"

  cidr_block              = cidrsubnet(var.env_cidr, 6, 63)
  public_mgmt_prefix_list = module.pl-mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = false

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  routing_scenario = 1

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}


module "vpc-env1" {
  source = "../modules/vpc"

  name = "${var.name}-env1"

  cidr_block              = cidrsubnet(var.env_cidr, 6, 0)
  public_mgmt_prefix_list = module.pl-mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = false

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  routing_scenario = 1

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}


module "vpc-env2" {
  source = "../modules/vpc"

  name = "${var.name}-env2"

  cidr_block              = cidrsubnet(var.env_cidr, 6, 1)
  public_mgmt_prefix_list = module.pl-mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = false

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  routing_scenario = 1

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}
