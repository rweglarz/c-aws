# routing:
#   workload dg via cloud wan
#   workload mgmt-pl via igw
# vpc config:
#   subnets = {
#     "corea-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
#     "corea-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
#     "workload-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
#     "workload-b" : { "idx" : 3, "zone" : var.availability_zones[1] },
#   }

locals {
  rs6 = {
    workload = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==6) && strcontains(k, "workload-")) }
    corea = { for k,v in aws_subnet.this: v.availability_zone => v if ((var.routing_scenario==6) && strcontains(k, "corea-")) }
  }
}

resource "aws_route_table" "rs6-workload" {
  count = var.routing_scenario==6 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-rs6-workload"
  }
}

resource "aws_route" "rs6-workload-dg" {
  count = var.routing_scenario==6 ? 1 : 0

  route_table_id         = aws_route_table.rs6-workload[0].id
  destination_cidr_block = "0.0.0.0/0"
  core_network_arn       = var.core_network_arn
  depends_on = [ 
    aws_networkmanager_vpc_attachment.cwan 
  ]
}

resource "aws_route" "rs6-workload-mgmt" {
  count = var.routing_scenario==6 ? 1 : 0

  route_table_id             = aws_route_table.rs6-workload[0].id
  destination_prefix_list_id = var.public_mgmt_prefix_list
  gateway_id                 = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "rs6-workload" {
  for_each = local.rs6.workload

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rs6-workload[0].id
}
