resource "aws_route_table" "via_tgw" {
  count = (var.connect_tgw == true) ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-via_tgw"
  }
}
resource "aws_route" "via_tgw" {
  count = (var.connect_tgw==true) ? 1 : 0

  route_table_id         = aws_route_table.via_tgw[0].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table" "via_igw" {
  count = (var.deploy_igw==true) ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-via_igw"
  }
}
resource "aws_route" "via_igw" {
  count = (var.deploy_igw==true) ? 1 : 0

  route_table_id         = aws_route_table.via_igw[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table" "via_mixed" {
  count = (var.deploy_igw==true && var.connect_tgw) ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-via_mixed"
  }
}
resource "aws_route" "via_mixed-igw" {
  count = (var.deploy_igw==true && var.connect_tgw==true) ? 1 : 0

  route_table_id         = aws_route_table.via_mixed[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}
resource "aws_route" "via_mixed-tgw" {
  count = (var.deploy_igw==true && var.connect_tgw==true) ? 1 : 0

  route_table_id         = aws_route_table.via_mixed[0].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.transit_gateway_id
}
