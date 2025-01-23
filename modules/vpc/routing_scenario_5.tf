# routing:
#   workload dg via gwlbe
#   gwlbe dg via tgw
#   workload mgmt-pl via igw
# vpc config:
#   subnets = {
#     "tgwa-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
#     "tgwa-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
#     "gwlbe-a" : { "idx" : 2, "zone" : var.availability_zones[0], "tags": {"pan_zone": "env1"} },
#     "gwlbe-b" : { "idx" : 3, "zone" : var.availability_zones[1], "tags": {"pan_zone": "env1"} },
#     "workload-a" : { "idx" : 4, "zone" : var.availability_zones[0] },
#     "workload-b" : { "idx" : 5, "zone" : var.availability_zones[1] },
#   }

locals {
  rs5 = {
    workload = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==5) && strcontains(k, "workload-")) }
    gwlbe = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==5) && strcontains(k, "gwlbe-")) }
    tgwa = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==5) && strcontains(k, "tgwa-")) }
  }
}

resource "aws_vpc_endpoint" "rs5-gwlbe" {
  for_each = local.rs5.gwlbe

  subnet_ids        = [each.value.id]
  vpc_id            = aws_vpc.this.id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  tags = {
    Name = "${var.name}-rs5-gwlbe-${each.key}"
  }
  lifecycle { create_before_destroy = true }
}



resource "aws_route_table" "rs5-tgwa" {
  count = var.routing_scenario==5 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs5-tgwa"
  }
}

resource "aws_route" "rs5-tgwa--workload" {
  for_each = local.rs5.workload

  route_table_id         = aws_route_table.rs5-tgwa[0].id
  destination_cidr_block = each.value.cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.rs5-gwlbe[each.key].id
}

resource "aws_route_table_association" "rs5-tgwa" {
  for_each = local.rs5.tgwa

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs5-tgwa[0].id
}



resource "aws_route_table" "rs5-gwlbe" {
  count = var.routing_scenario==5 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs5-gwlbe"
  }
}

resource "aws_route" "rs5-gwlbe" {
  count = var.routing_scenario==5 ? 1 : 0

  route_table_id         = aws_route_table.rs5-gwlbe[0].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs5-gwlbe" {
  for_each = local.rs5.gwlbe

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs5-gwlbe[0].id
}




resource "aws_route_table" "rs5-workload" {
  for_each = local.rs5.workload

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs5-workload-${each.key}"
  }
}

resource "aws_route" "rs5-workload-dg" {
  for_each = local.rs5.workload

  route_table_id         = aws_route_table.rs5-workload[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.rs5-gwlbe[each.key].id
}

resource "aws_route" "rs5-workload-mgmt" {
  for_each = local.rs5.workload

  route_table_id             = aws_route_table.rs5-workload[each.key].id
  destination_prefix_list_id = var.public_mgmt_prefix_list
  gateway_id                 = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs5-workload" {
  for_each = local.rs5.workload

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs5-workload[each.key].id
}
