# routing:
#   workload dg via gwlbe
#   rfc1918  via tgw
# vpc config:
  # subnets = {
  #   "tgwa-a"   : { "idx" :  0, "zone" : var.availability_zones[0] },
  #   "tgwa-b"   : { "idx" :  1, "zone" : var.availability_zones[1] },
  #   "lambda-a" : { "idx" :  2, "zone" : var.availability_zones[0] },
  #   "lambda-b" : { "idx" :  3, "zone" : var.availability_zones[1] },
  #   "gwlb-a"   : { "idx" :  4, "zone" : var.availability_zones[0] },
  #   "gwlb-b"   : { "idx" :  5, "zone" : var.availability_zones[1] },
  #   "mgmt-a"   : { "idx" :  6, "zone" : var.availability_zones[0] },
  #   "mgmt-b"   : { "idx" :  7, "zone" : var.availability_zones[1] },
  #   "fwprv-a"  : { "idx" :  8, "zone" : var.availability_zones[0] },
  #   "fwprv-b"  : { "idx" :  9, "zone" : var.availability_zones[1] },
  #   "fwpub-a"  : { "idx" : 10, "zone" : var.availability_zones[0] },
  #   "fwpub-b"  : { "idx" : 11, "zone" : var.availability_zones[1] },
  #   "gwlbe-a"  : { "idx" : 12, "zone" : var.availability_zones[0] },
  #   "gwlbe-b"  : { "idx" : 13, "zone" : var.availability_zones[1] },
  #   "natgw-a"  : { "idx" : 14, "zone" : var.availability_zones[0] },
  #   "natgw-b"  : { "idx" : 15, "zone" : var.availability_zones[1] },
  # }

#   }

locals {
  rs3 = {
    tgwa = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "tgwa-")) }
    lambda = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "lambda-")) }
    mgmt = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "mgmt-")) }
    fwprv = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "fwprv-")) }
    fwpub = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "fwpub-")) }
    gwlbe = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "gwlbe-")) }
    natgw = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==3) && strcontains(k, "natgw-")) }
  }
}



resource "aws_vpc_endpoint" "rs3-gwlbe" {
  for_each = local.rs3.gwlbe

  subnet_ids        = [each.value.id]
  vpc_id            = aws_vpc.this.id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  tags = {
    Name = "${var.name}-rs3-gwlbe-${each.key}"
  }
  lifecycle { create_before_destroy = true }
}



resource "aws_route_table" "rs3-gwlbe" {
  count = var.routing_scenario==3 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs3-gwlbe"
  }
}

resource "aws_route" "rs3-gwlbe" {
  count = var.routing_scenario==3 ? 1 : 0

  route_table_id         = aws_route_table.rs3-gwlbe[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs3-gwlbe" {
  for_each = local.rs3.gwlbe

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs3-gwlbe[0].id
}


resource "aws_route_table" "rs3-lambda" {
  for_each = local.rs3.lambda

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs3-lambda"
  }
}

resource "aws_route" "rs3-lambda-dg" {
  for_each = local.rs3.lambda

  route_table_id         = aws_route_table.rs3-lambda[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "rs3-lambda" {
  for_each = local.rs3.lambda

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs3-lambda[each.key].id
}



resource "aws_route_table" "rs3-fwprv" {
  for_each = local.rs3.fwprv

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs3-fwprv-${each.key}"
  }
}

resource "aws_route" "rs3-fwprv-172-16" {
  for_each = local.rs3.fwprv

  route_table_id         = aws_route_table.rs3-fwprv[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs3-fwprv" {
  for_each = local.rs3.fwprv

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs3-fwprv[each.key].id
}


resource "aws_route_table" "rs3-mgmt" {
  for_each = local.rs3.mgmt

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs3-mgmt"
  }
}

resource "aws_route" "rs3-mgmt-dg" {
  for_each = local.rs3.mgmt

  route_table_id         = aws_route_table.rs3-mgmt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route" "rs3-mgmt-172" {
  for_each = local.rs3.mgmt

  route_table_id         = aws_route_table.rs3-mgmt[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs3-mgmt" {
  for_each = local.rs3.mgmt

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs3-mgmt[each.key].id
}





resource "aws_route_table" "rs3-natgw" {
  for_each = local.rs3.mgmt

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs3-natgw"
  }
}

resource "aws_route" "rs3-natgw-dg" {
  for_each = local.rs3.natgw

  route_table_id         = aws_route_table.rs3-natgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs3-natgw" {
  for_each = local.rs3.natgw

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs3-natgw[each.key].id
}



# resource "aws_route" "rs3-igw-workload" {
#   for_each = local.rs3.workload

#   route_table_id         = aws_route_table.rs3-igw[0].id
#   destination_cidr_block = each.value.cidr_block
#   vpc_endpoint_id        = aws_vpc_endpoint.rs3-gwlbe[each.key].id
# }

# resource "aws_route_table_association" "rs3-igw" {
#   count = var.routing_scenario==3 ? 1 : 0

#   gateway_id     = aws_internet_gateway.this[0].id
#   route_table_id = aws_route_table.rs3-igw[0].id
# }
