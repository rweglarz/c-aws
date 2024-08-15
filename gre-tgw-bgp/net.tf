resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn                 = local.asn.tgw
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [local.cidr.tgw]
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "${var.name}-hub"
  }
}

resource "aws_ec2_transit_gateway_route_table" "jumphost" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "${var.name}-jumphost"
  }
}

module "vpc_hub" {
  source = "../modules/vpc"

  name = "${var.name}-hub"

  cidr_block              = local.cidr.hub
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips
  deploy_igw         = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id

  subnets = {
    "mgmt-a"    : { "idx" : 0, "zone" : var.availability_zones[0] },
    "mgmt-b"    : { "idx" : 1, "zone" : var.availability_zones[1] },
    "private-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
    "private-b" : { "idx" : 3, "zone" : var.availability_zones[1] },
    "tgwa-a"    : { "idx" : 4, "zone" : var.availability_zones[0] },
    "tgwa-b"    : { "idx" : 5, "zone" : var.availability_zones[1] },
  }
}

module "vpc_jumphost" {
  source = "../modules/vpc"

  name = "${var.name}-jumphost"

  cidr_block              = local.cidr.hub
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips
  deploy_igw         = true

  routing_scenario = 1
  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.jumphost.id

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "tgwa-a"     : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}


locals {
  vpc_env_t = flatten([
    for env,env_v in var.envs : [
      for vpc,vpc_v in env_v.vpcs : {
         name = "${env}-${vpc}"
         idx  = (env_v.idx - 1)*2 + (vpc=="a" ? 1 : 2)
         env = env
      }
    ]
  ])
  vpc_env = { for v in local.vpc_env_t: v.name => v }
}



module "vpc_env" {
  source = "../modules/vpc"
  for_each = local.vpc_env

  name = "${var.name}-${each.key}"

  cidr_block              = cidrsubnet(var.cidr, 9, 18 + each.value.idx)
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips
  deploy_igw              = false

  routing_scenario = 0
  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[each.value.env].id

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "tgwa-a"     : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}




resource "aws_route_table" "hub" {
  vpc_id = module.vpc_hub.vpc.id
  tags = {
    Name = "${var.name}-hub"
  }
}

resource "aws_route" "hub-dg-igw" {
  route_table_id         = aws_route_table.hub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc_hub.internet_gateway_id
}

resource "aws_route" "hub-172-tgw" {
  route_table_id         = aws_route_table.hub.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route_table_association" "hub-mgmt" {
  for_each = {
    mgmt-a    = module.vpc_hub.subnets.mgmt-a.id,
    mgmt-b    = module.vpc_hub.subnets.mgmt-b.id,
    private-a = module.vpc_hub.subnets.private-a.id,
    private-b = module.vpc_hub.subnets.private-b.id,
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.hub.id
}



resource "aws_ec2_transit_gateway_connect" "this" {
  for_each = var.envs

  transit_gateway_id      = aws_ec2_transit_gateway.this.id
  transport_attachment_id = module.vpc_hub.transit_gateway_attachment_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_connect_peer" "fw1" {
  for_each = aws_ec2_transit_gateway_connect.this

  transit_gateway_attachment_id = each.value.id
  inside_cidr_blocks = [cidrsubnet("169.254.100.0/22", 7, 0 + var.envs[each.key].idx)]
  peer_address       = module.fw1.private_ip_list.private[0]
  bgp_asn            = local.asn.fw
}

resource "aws_ec2_transit_gateway_connect_peer" "fw2" {
  for_each = aws_ec2_transit_gateway_connect.this

  transit_gateway_attachment_id = each.value.id
  inside_cidr_blocks = [cidrsubnet("169.254.100.0/22", 7, 8 + var.envs[each.key].idx)]
  peer_address       = module.fw2.private_ip_list.private[0]
  bgp_asn            = local.asn.fw
}



resource "aws_ec2_transit_gateway_route_table" "spokes" {
  for_each = var.envs

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "${var.name}-spokes-${each.key}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "fw" {
  for_each = var.envs

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "${var.name}-fw-${each.key}"
  }
}


resource "aws_ec2_transit_gateway_route_table_association" "fw" {
  for_each = var.envs

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw[each.key].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes-to-fw" {
  for_each = local.vpc_env

  transit_gateway_attachment_id  = module.vpc_env[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw[each.value.env].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "fw-to-spokes" {
  for_each = var.envs

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[each.key].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes-to-jumphost" {
  for_each = local.vpc_env

  transit_gateway_attachment_id  = module.vpc_env[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.jumphost.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "jumphost-to-spokes" {
  for_each = var.envs

  transit_gateway_attachment_id  = module.vpc_jumphost.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[each.key].id
}
