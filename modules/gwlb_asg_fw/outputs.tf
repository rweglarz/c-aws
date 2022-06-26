output aws_ec2_transit_gateway_vpc_attachment_id {
  value = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output aws_ec2_transit_gateway_route_table_id {
  value = aws_ec2_transit_gateway_route_table.this.id
}

output aws_vpc_endpoint_service_name {
  value = aws_vpc_endpoint_service.this.service_name
}
