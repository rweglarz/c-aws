resource "aws_ec2_transit_gateway" "tgw" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [var.tgw_cidr]
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-spokes"
  }
}

resource "aws_ec2_transit_gateway_route_table" "sec" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-sec"
  }
}

resource "aws_ec2_transit_gateway_route" "spoke-dg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.vpc-sec.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}



resource "aws_ec2_transit_gateway_route_table_propagation" "vpc--to--sec" {
  for_each = {
    mgmt = module.vpc-mgmt.transit_gateway_attachment_id
    env1 = module.vpc-env1.transit_gateway_attachment_id
    env2 = module.vpc-env2.transit_gateway_attachment_id
  }
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}
