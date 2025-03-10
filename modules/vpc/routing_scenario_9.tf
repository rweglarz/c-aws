# routing: setup for security vpc
#   tgwa dg via gwlbe
#   gwlbe dg via natgw
#   fwpub dg via igw
#   natgw dg via igw
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
  rs9 = {
    tgwa = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "tgwa-")) }
    tgwa6 = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9 && var.dual_stack) && strcontains(k, "tgwa-")) }
    lambda = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "lambda-")) }
    mgmt = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "mgmt-")) }
    fwprv = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "fwprv-")) }
    fwpub = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "fwpub-")) }
    fwpub6 = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9 && var.dual_stack) && strcontains(k, "fwpub-")) }
    gwlbe = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "gwlbe-")) }
    gwlbe6 = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9 && var.dual_stack) && strcontains(k, "gwlbe-")) }
    natgw = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==9) && strcontains(k, "natgw-")) }
  }
}



resource "aws_vpc_endpoint" "rs9-gwlbe" {
  for_each = local.rs9.gwlbe

  subnet_ids        = [each.value.id]
  vpc_id            = aws_vpc.this.id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  ip_address_type   = var.dual_stack ? "dualstack" : "ipv4"

  tags = {
    Name = "${var.name}-rs9-gwlbe-${each.key}"
  }
  lifecycle { create_before_destroy = true }
}



resource "aws_route_table" "rs9-gwlbe" {
  for_each = local.rs9.gwlbe

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-gwlbe-${each.key}"
  }
}

resource "aws_route" "rs9-gwlbe-10" {
  for_each = local.rs9.gwlbe

  route_table_id         = aws_route_table.rs9-gwlbe[each.key].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route" "rs9-gwlbe-172-16" {
  for_each = local.rs9.gwlbe

  route_table_id         = aws_route_table.rs9-gwlbe[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route" "rs9-gwlbe-192-168" {
  for_each = local.rs9.gwlbe

  route_table_id         = aws_route_table.rs9-gwlbe[each.key].id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route" "rs9-gwlbe-fd" {
  for_each = local.rs9.gwlbe6

  route_table_id              = aws_route_table.rs9-gwlbe[each.key].id
  destination_ipv6_cidr_block = "fd00::/8"
  transit_gateway_id          = var.transit_gateway_id
}

resource "aws_route" "rs9-gwlbe-dg" {
  for_each = local.rs9.gwlbe

  route_table_id         = aws_route_table.rs9-gwlbe[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "rs9-gwlbe" {
  for_each = local.rs9.gwlbe

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-gwlbe[each.key].id
}


resource "aws_route_table" "rs9-lambda" {
  for_each = local.rs9.lambda

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-lambda-${each.key}"
  }
}

resource "aws_route" "rs9-lambda-dg" {
  for_each = local.rs9.lambda

  route_table_id         = aws_route_table.rs9-lambda[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "rs9-lambda" {
  for_each = local.rs9.lambda

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-lambda[each.key].id
}



resource "aws_route_table" "rs9-fwprv" {
  for_each = local.rs9.fwprv

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-fwprv-${each.key}"
  }
}

resource "aws_route" "rs9-fwprv-172-16" {
  for_each = local.rs9.fwprv

  route_table_id         = aws_route_table.rs9-fwprv[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs9-fwprv" {
  for_each = local.rs9.fwprv

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-fwprv[each.key].id
}



resource "aws_route_table" "rs9-fwpub" {
  for_each = local.rs9.mgmt

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-fwpub-${each.key}"
  }
}

resource "aws_route" "rs9-fwpub-dg" {
  for_each = local.rs9.fwpub

  route_table_id         = aws_route_table.rs9-fwpub[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "rs9-fwpub-dg-ipv6" {
  for_each = local.rs9.fwpub6

  route_table_id              = aws_route_table.rs9-fwpub[each.key].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs9-fwpub" {
  for_each = local.rs9.fwpub

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-fwpub[each.key].id
}



resource "aws_route_table" "rs9-mgmt" {
  for_each = local.rs9.mgmt

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-mgmt"
  }
}

resource "aws_route" "rs9-mgmt-dg" {
  for_each = local.rs9.mgmt

  route_table_id         = aws_route_table.rs9-mgmt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route" "rs9-mgmt-172" {
  for_each = local.rs9.mgmt

  route_table_id         = aws_route_table.rs9-mgmt[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs9-mgmt" {
  for_each = local.rs9.mgmt

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-mgmt[each.key].id
}





resource "aws_route_table" "rs9-natgw" {
  for_each = local.rs9.mgmt

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-natgw-${each.key}"
  }
}

resource "aws_route" "rs9-natgw-172-16" {
  for_each = local.rs9.gwlbe

  route_table_id         = aws_route_table.rs9-natgw[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = aws_vpc_endpoint.rs9-gwlbe[each.key].id
}

resource "aws_route" "rs9-natgw-dg" {
  for_each = local.rs9.natgw

  route_table_id         = aws_route_table.rs9-natgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs9-natgw" {
  for_each = local.rs9.natgw

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-natgw[each.key].id
}




resource "aws_route_table" "rs9-tgwa" {
  for_each = local.rs9.tgwa

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs9-tgwa-${each.key}"
  }
}

resource "aws_route" "rs9-tgwa--dg" {
  for_each = local.rs9.tgwa

  route_table_id         = aws_route_table.rs9-tgwa[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.rs9-gwlbe[each.key].id
}

resource "aws_route" "rs9-tgwa--dg-ipv6" {
  for_each = local.rs9.tgwa6

  route_table_id              = aws_route_table.rs9-tgwa[each.key].id
  destination_ipv6_cidr_block = "::/0"
  vpc_endpoint_id             = aws_vpc_endpoint.rs9-gwlbe[each.key].id
}

resource "aws_route_table_association" "rs9-tgwa" {
  for_each = local.rs9.tgwa

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs9-tgwa[each.key].id
}
