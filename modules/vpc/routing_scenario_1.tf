# routing:
#   workload dg via tgwa
#   workload mgmt-pl via igw
# vpc config:
#   subnets = {
#     "tgwa-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
#     "tgwa-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
#     "workload-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
#     "workload-b" : { "idx" : 3, "zone" : var.availability_zones[1] },
#   }

locals {
  rs1 = {
    workload = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==1) && strcontains(k, "workload-")) }
    tgwa = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==1) && strcontains(k, "tgwa-")) }
  }
}

resource "aws_route_table" "rs1-workload" {
  count = var.routing_scenario==1 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs1-workload"
  }
}

resource "aws_route" "rs1-workload-dg" {
  count = var.routing_scenario==1 ? 1 : 0

  route_table_id         = aws_route_table.rs1-workload[0].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route" "rs1-workload-dg-ipv6" {
  count = (var.routing_scenario==1 && var.dual_stack) ? 1 : 0

  route_table_id              = aws_route_table.rs1-workload[0].id
  destination_ipv6_cidr_block = "::/0"
  transit_gateway_id          = var.transit_gateway_id
}

resource "aws_route" "rs1-workload-mgmt" {
  count = var.routing_scenario==1 ? 1 : 0

  route_table_id             = aws_route_table.rs1-workload[0].id
  destination_prefix_list_id = var.public_mgmt_prefix_list
  gateway_id                 = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs1-workload" {
  for_each = local.rs1.workload

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs1-workload[0].id
}
