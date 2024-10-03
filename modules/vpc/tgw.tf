resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = (var.connect_tgw == true) ? 1 : 0

  vpc_id                 = aws_vpc.this.id
  subnet_ids             = [for s in aws_subnet.this : s.id if length(regexall("-tgwa", s.tags.Name)) > 0]
  transit_gateway_id     = var.transit_gateway_id
  appliance_mode_support = try(var.appliance_mode, var.tgw_appliance_mode, false) ? "enable" : "disable"

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = var.name
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count = (var.connect_tgw == true) ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
