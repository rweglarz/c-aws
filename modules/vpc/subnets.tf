locals {
  extra_mask_bits = 28 - tonumber(split("/", aws_vpc.this.cidr_block)[1])
}


resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, local.extra_mask_bits, each.value.idx)
  availability_zone = each.value.zone
  tags = {
    Name = "${var.name}-${each.key}"
  }
}
