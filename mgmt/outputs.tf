output "aws_vpc_mgmt_id" {
  value = aws_vpc.mgmt.id
}

output "aws_subnet_mgmt_id" {
  value = aws_subnet.mgmt[*].id
}

output "aws_route_table_mgmt_id" {
  value = aws_route_table.mgmt.id
}

output "prefix_list-csp_nat_ips" {
  value = aws_ec2_managed_prefix_list.csp_nat_ips.id
}

output "prefix_list-mgmt_ips-eu_west_1" {
  value = module.pl-eu_west_1-mgmt_ips.id
}
output "prefix_list-mgmt_ips-eu_west_3" {
  value = module.pl-eu_west_3-mgmt_ips.id
}
