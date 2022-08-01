resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags = {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-int-igw"
  }
}

resource "aws_subnet" "tgwa" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 0 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-tgwa-${count.index}"
  }
}
resource "aws_subnet" "gwlbe-internal" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 2 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-gwlbe-internal-${count.index}"
  }
}
resource "aws_subnet" "gwlbe-outbound" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 4 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-gwlbe-outbound-${count.index}"
  }
}
resource "aws_subnet" "gwlb" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 6 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-gwlb-${count.index}"
  }
}
resource "aws_subnet" "fw" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 8 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-${count.index}"
  }
}
resource "aws_subnet" "mgmt" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 10 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-mgmt-${count.index}"
  }
}
resource "aws_subnet" "untrust" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 12 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-untrust-${count.index}"
  }
}
resource "aws_subnet" "natgw" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 14 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-natgw-${count.index}"
  }
}
resource "aws_eip" "natgw" {
  count = length(var.availability_zones)
  tags = {
    Name = "${var.name}-natgw-${count.index}"
  }
}
resource "aws_nat_gateway" "this" {
  count         = length(var.availability_zones)
  subnet_id     = aws_subnet.natgw[count.index].id
  allocation_id = aws_eip.natgw[count.index].id

  tags = {
    Name = "${var.name}-natgw-${count.index}"
  }
  depends_on = [aws_internet_gateway.this]
}

resource "aws_vpc_endpoint" "internal" {
  count = length(var.availability_zones)

  subnet_ids        = [aws_subnet.gwlbe-internal[count.index].id]
  vpc_id            = aws_vpc.this.id
  service_name      = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    # Workaround for error "InvalidParameter: Endpoint must be removed from route table before deletion".
    create_before_destroy = true
  }
  tags = {
    pan_zone = "internal"
  }
}
resource "aws_vpc_endpoint" "outbound" {
  count = length(var.availability_zones)

  subnet_ids        = [aws_subnet.gwlbe-outbound[count.index].id]
  vpc_id            = aws_vpc.this.id
  service_name      = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    # Workaround for error "InvalidParameter: Endpoint must be removed from route table before deletion".
    create_before_destroy = true
  }
  tags = {
    pan_zone = "outbound"
  }
}


resource "aws_route_table" "tgwa" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-tgwa-rt"
  }
}
resource "aws_route_table_association" "tgwa" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.tgwa[count.index].id
  route_table_id = aws_route_table.tgwa[count.index].id
}
resource "aws_route" "tgwa-dg" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.tgwa[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.outbound[count.index].id
}
resource "aws_route" "tgwa-172" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.tgwa[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = aws_vpc_endpoint.internal[count.index].id
}

resource "aws_route_table" "gwlbe-internal" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-gwlbe-internal-${count.index}"
  }
}
resource "aws_route_table" "gwlbe-outbound" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-gwlbe-outbound-${count.index}"
  }
}
resource "aws_route_table_association" "gwlbe-internal" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.gwlbe-internal[count.index].id
  route_table_id = aws_route_table.gwlbe-internal[count.index].id
}
resource "aws_route_table_association" "gwlbe-outbound" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.gwlbe-outbound[count.index].id
  route_table_id = aws_route_table.gwlbe-outbound[count.index].id
}
resource "aws_route" "gwlbe-internal-prv" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.gwlbe-internal[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.tgw
}
resource "aws_route" "gwlbe-outbound-prv" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.gwlbe-outbound[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.tgw
}
resource "aws_route" "gwlbe-dg" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.gwlbe-outbound[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

/*
resource "aws_route_table" "fw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-fw-rt"
  }
}
resource "aws_route_table_association" "fw" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.fw_gwlb[count.index].id
  route_table_id = aws_route_table.fw.id
}
resource "aws_route" "fw-dg" {
  route_table_id         = aws_route_table.fw.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
}
*/

resource "aws_route_table" "mgmt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-fw-mgmt-${count.index}"
  }
}
resource "aws_route_table_association" "mgmt" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.mgmt[count.index].id
}
resource "aws_route" "mgmt-prv" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.mgmt[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = var.tgw
}
resource "aws_route" "mgmt-dg-natgw" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.mgmt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table" "natgw" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-natgw-${count.index}"
  }
}
resource "aws_route_table_association" "natgw" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.natgw[count.index].id
  route_table_id = aws_route_table.natgw[count.index].id
}
resource "aws_route" "natgw-prv" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.natgw[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = aws_vpc_endpoint.outbound[count.index].id
}
resource "aws_route" "natgw-dg" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.natgw[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}


resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                                          = aws_vpc.this.id
  subnet_ids                                      = aws_subnet.tgwa[*].id
  transit_gateway_id                              = var.tgw
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = "enable"
  tags = {
    Name = "${var.name}"
  }
}
resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = var.tgw
  tags = {
    Name = "${var.name}"
  }
}
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}
