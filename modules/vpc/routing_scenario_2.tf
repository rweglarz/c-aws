# routing:
#   workload dg via gwlbe
#   gwlbe dg via igw
#   rfc1918  via tgw
# vpc config:
#   subnets = {
#     "tgwa-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
#     "tgwa-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
#     "workload-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
#     "workload-b" : { "idx" : 3, "zone" : var.availability_zones[1] },
#     "gwlbe-a" : { "idx" : 2, "zone" : var.availability_zones[0], "tags": {"pan_zone": "env1"} },
#     "gwlbe-b" : { "idx" : 3, "zone" : var.availability_zones[1], "tags": {"pan_zone": "env1"} },
#   }

locals {
  rs2 = {
    workload = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==2) && strcontains(k, "workload-")) }
    workload6 = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==2) && strcontains(k, "workload-")) }
    gwlbe = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==2) && strcontains(k, "gwlbe-")) }
  }
}



resource "aws_vpc_endpoint" "rs2-gwlbe" {
  for_each = local.rs2.gwlbe

  subnet_ids        = [each.value.id]
  vpc_id            = aws_vpc.this.id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  ip_address_type   = coalesce(
    try(each.value.ipv6_native, false) && var.ipv6 ? "ipv6" : null,
    var.ipv6 ? "dualstack" : null,
    "ipv4"
  )

  tags = {
    Name = "${var.name}-rs2-gwlbe-${each.key}"
  }
  lifecycle { create_before_destroy = true }
}



resource "aws_route_table" "rs2-gwlbe" {
  count = var.routing_scenario==2 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs2-gwlbe"
  }
}

resource "aws_route" "rs2-gwlbe-dg" {
  count = var.routing_scenario==2 ? 1 : 0

  route_table_id         = aws_route_table.rs2-gwlbe[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "rs2-gwlbe-dg-ipv6" {
  count = (var.routing_scenario==2 && var.ipv6) ? 1 : 0

  route_table_id              = aws_route_table.rs2-gwlbe[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs2-gwlbe" {
  for_each = local.rs2.gwlbe

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs2-gwlbe[0].id
}



resource "aws_route_table" "rs2-workload" {
  for_each = local.rs2.workload

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs2-workload-${each.key}"
  }
}

resource "aws_route" "rs2-workload-dg" {
  for_each = local.rs2.workload

  route_table_id         = aws_route_table.rs2-workload[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.rs2-gwlbe[each.key].id
}

resource "aws_route" "rs2-workload-dg-ipv6" {
  for_each = local.rs2.workload6

  route_table_id              = aws_route_table.rs2-workload[each.key].id
  destination_ipv6_cidr_block = "::/0"
  vpc_endpoint_id             = aws_vpc_endpoint.rs2-gwlbe[each.key].id
}


resource "aws_route" "rs2-workload-172-16" {
  for_each = { for k,v in local.rs2.workload: k => v if var.connect_tgw }

  route_table_id         = aws_route_table.rs2-workload[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs2-workload" {
  for_each = local.rs2.workload

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs2-workload[each.key].id
}



resource "aws_route_table" "rs2-igw" {
  count = var.routing_scenario==2 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs2-igw"
  }
}

resource "aws_route" "rs2-igw-workload" {
  for_each = local.rs2.workload

  route_table_id         = aws_route_table.rs2-igw[0].id
  destination_cidr_block = each.value.cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.rs2-gwlbe[each.key].id
}

resource "aws_route" "rs2-igw-workload-ipv6" {
  for_each = local.rs2.workload6

  route_table_id              = aws_route_table.rs2-igw[0].id
  destination_ipv6_cidr_block = each.value.ipv6_cidr_block
  vpc_endpoint_id             = aws_vpc_endpoint.rs2-gwlbe[each.key].id
}

resource "aws_route_table_association" "rs2-igw" {
  count = var.routing_scenario==2 ? 1 : 0

  gateway_id     = aws_internet_gateway.this[0].id
  route_table_id = aws_route_table.rs2-igw[0].id
}
