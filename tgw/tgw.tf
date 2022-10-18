resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.asn["no"]
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
resource "aws_ec2_transit_gateway_route" "spoke-dg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.mfw.aws_ec2_transit_gateway_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}


output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.tgw.id
}
output "security_transit_gateway_vpc_attachment_id" {
  value = module.mfw.aws_ec2_transit_gateway_vpc_attachment_id
}
output "transit_gateway_route_tables" {
  value = {
    spoke = aws_ec2_transit_gateway_route_table.spoke.id,
    sec   = module.mfw.aws_ec2_transit_gateway_route_table_id
    mgmt  = aws_ec2_transit_gateway_route_table.mgmt.id,
  }
}
