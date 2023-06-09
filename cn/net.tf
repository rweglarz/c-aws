module "vpc_eks" {
  source = "../modules/vpc"

  name = "${var.name}-eks"

  enable_dns_hostnames = true

  cidr_block              = var.cidr
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = true

  connect_tgw = false

  subnets = {
    "mgmt" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "natgw-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
    "natgw-b" : { "idx" : 2, "zone" : var.availability_zones[1] },
    "k8s-cp-a" : { "idx" : 3, "zone" : var.availability_zones[0] },
    "k8s-cp-b" : { "idx" : 4, "zone" : var.availability_zones[1] },
    "k8s-m-a" : { "idx" : 1, "zone" : var.availability_zones[0], "subnet_mask_length" : 24 },
    "k8s-m-b" : { "idx" : 2, "zone" : var.availability_zones[1], "subnet_mask_length" : 24 },
    "k8s-ci-a" : { "idx" : 49, "zone" : var.availability_zones[0] },
    "k8s-ti-a" : { "idx" : 50, "zone" : var.availability_zones[1] },
    "k8s-d3-b" : { "idx" : 51, "zone" : var.availability_zones[1] },
    "k8s-d4-b" : { "idx" : 52, "zone" : var.availability_zones[1] },
  }
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = module.vpc_eks.subnets["mgmt"].id
  route_table_id = module.vpc_eks.route_tables["via_igw"]
}


resource "aws_route_table" "via_natgw" {
  for_each = { for k, v in module.vpc_eks.subnets : v.availability_zone => v if length(regexall("natgw-", k)) > 0 }

  vpc_id = module.vpc_eks.vpc.id
  tags = {
    Name = "${var.name}-via-natgw-${each.key}"
  }
}

resource "aws_route" "via_natgw-dg" {
  for_each = { for k, v in module.vpc_eks.subnets : v.availability_zone => v if length(regexall("natgw-", k)) > 0 }

  route_table_id         = aws_route_table.via_natgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc_eks.nat_gateways[each.key].id
}


resource "aws_route_table_association" "k8s" {
  for_each = { for k, v in module.vpc_eks.subnets : k => v if length(regexall("k8s-", k)) > 0 }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.via_natgw[each.value.availability_zone].id
}

resource "aws_route_table_association" "natgw" {
  for_each = { for k, v in module.vpc_eks.subnets : k => v if length(regexall("natgw-", k)) > 0 }

  subnet_id      = each.value.id
  route_table_id = module.vpc_eks.route_tables["via_igw"]
}


