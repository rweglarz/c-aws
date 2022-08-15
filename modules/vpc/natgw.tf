locals {
  natgw_enabled = (var.deploy_igw == true) && (var.deploy_natgw == true)
}

resource "aws_eip" "natgw" {
  for_each = toset([for s in aws_subnet.this : s.availability_zone if(length(regexall("-natgw", s.tags.Name)) > 0) && (local.natgw_enabled == true)])
  tags = {
    Name = "${var.name}-natgw-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = { for k, v in aws_subnet.this : v.availability_zone => v if(length(regexall("-natgw", v.tags.Name)) > 0) && (local.natgw_enabled == true) }

  subnet_id     = each.value.id
  allocation_id = aws_eip.natgw[each.key].id

  depends_on = [
    aws_internet_gateway.this[0]
  ]
  tags = {
    Name = "${var.name}-natgw-${each.key}"
  }
}

