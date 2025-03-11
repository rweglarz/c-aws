locals {
  extra_mask_bits = {
    for k, v in var.subnets: k => lookup(v, "subnet_mask_length", var.subnet_mask_length) - tonumber(split("/", aws_vpc.this.cidr_block)[1])
  }
}


resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.zone

  cidr_block                      = try(! each.value.ipv6_native, true) ? try(each.value.cidr_block, cidrsubnet(aws_vpc.this.cidr_block, local.extra_mask_bits[each.key], each.value.idx)) : null
  ipv6_cidr_block                 = try(cidrsubnet(aws_vpc_ipv6_cidr_block_association.this[0].ipv6_cidr_block, 8, each.value.idx), null)
  assign_ipv6_address_on_creation = var.ipv6
  ipv6_native                     = try(each.value.ipv6_native, false)

  enable_resource_name_dns_aaaa_record_on_launch = var.ipv6

  tags = merge(
    { Name = "${var.name}-${each.key}" },
    { for tk,tv in lookup(each.value, "tags", {}): tk=>tv }
  )

  depends_on = [ 
    aws_vpc_ipv4_cidr_block_association.this 
  ]
}
