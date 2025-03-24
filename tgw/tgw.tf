resource "aws_vpc_ipam_pool_cidr_allocation" "tgw" {
  count = var.dual_stack ? 1 : 0

  ipam_pool_id   = aws_vpc_ipam_pool.ipv6_private[0].id
}


resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.asn["no"]
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = concat(
    [var.tgw_cidr],
    try(aws_vpc_ipam_pool_cidr_allocation.tgw[0].cidr, [])  #ipv6
  )
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "sec" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-sec"
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
  transit_gateway_attachment_id  = module.vpc_sec.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "spoke-dg-ipv6" {
  count = var.dual_stack ? 1 : 0
  destination_cidr_block         = "::/0"
  transit_gateway_attachment_id  = module.vpc_sec.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}


output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.tgw.id
}
output "security_transit_gateway_vpc_attachment_id" {
  value = module.vpc_sec.transit_gateway_attachment_id
}
output "transit_gateway_route_tables" {
  value = {
    spoke = aws_ec2_transit_gateway_route_table.spoke.id,
    sec   = aws_ec2_transit_gateway_route_table.sec.id,
    # mgmt  = aws_ec2_transit_gateway_route_table.mgmt.id,
  }
}
