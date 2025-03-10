output "vpc" {
  value = aws_vpc.this
}


output "security_groups" {
  value = {
    private         = aws_security_group.private.id
    public_mgmt     = aws_security_group.public.id
    wide_open       = aws_security_group.open.id
    local_vpc       = aws_security_group.local_vpc.id
    managed_devices = aws_security_group.managed_devices.id
  }
}
output "sg_public_id" {
  value = aws_security_group.public.id
}
output "sg_open_id" {
  value = aws_security_group.open.id
}
output "sg_private_id" {
  value = aws_security_group.private.id
}

output "internet_gateway_id" {
  value = try(aws_internet_gateway.this[0].id, null)
}

output "subnets" {
  value = aws_subnet.this
}

output "transit_gateway_attachment_id" {
  value = try(aws_ec2_transit_gateway_vpc_attachment.this[0].id, null)
}

output "route_tables" {
  value = {
    via_igw   = try(aws_route_table.via_igw[0].id, null),
    via_tgw   = try(aws_route_table.via_tgw[0].id, null),
    via_mixed = try(aws_route_table.via_mixed[0].id, null),
    pfx_via_igw = try(aws_route_table.pfx_via_igw[0].id, null),
  }
}

output "customizable_route_tables" {
  value = {
    rs7-corea = {
      for k, v in aws_route_table.rs7-corea: k => v.id
    }
  }
}

output "nat_gateways" {
  value = aws_nat_gateway.this
}
