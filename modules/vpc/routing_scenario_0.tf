# routing:
#   workload dg via tgwa
# vpc config:
#   subnets = {
#     "tgwa-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
#     "tgwa-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
#     "workload-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
#     "workload-b" : { "idx" : 3, "zone" : var.availability_zones[1] },
#   }

locals {
  rs0 = {
    workload = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==0) && strcontains(k, "workload-")) }
    tgwa = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==0) && strcontains(k, "tgwa-")) }
  }
}

resource "aws_route_table" "rs0-workload" {
  count = var.routing_scenario==0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs0-workload"
  }
}

resource "aws_route" "rs0-workload-dg" {
  count = var.routing_scenario==0 ? 1 : 0

  route_table_id         = aws_route_table.rs0-workload[0].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "rs0-workload" {
  for_each = local.rs0.workload

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs0-workload[0].id
}
