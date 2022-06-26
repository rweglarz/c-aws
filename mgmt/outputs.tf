output aws_vpc_mgmt_id {
  value = aws_vpc.mgmt.id
}

output aws_subnet_mgmt_id {
  value = aws_subnet.mgmt[*].id
}

output aws_route_table_mgmt_id {
  value = aws_route_table.mgmt.id
}

