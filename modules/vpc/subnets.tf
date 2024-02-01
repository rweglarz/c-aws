locals {
  extra_mask_bits = {
    for k, v in var.subnets: k => lookup(v, "subnet_mask_length", var.subnet_mask_length) - tonumber(split("/", aws_vpc.this.cidr_block)[1])
  }
}


resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = try(each.value.cidr_block, cidrsubnet(aws_vpc.this.cidr_block, local.extra_mask_bits[each.key], each.value.idx))
  availability_zone = each.value.zone

  tags = merge(
    { Name = "${var.name}-${each.key}" },
    { for tk,tv in lookup(each.value, "tags", {}): tk=>tv }
  )

  depends_on = [ 
    aws_vpc_ipv4_cidr_block_association.this 
  ]
}
