resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags = {
    Name = "${var.name}"
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
resource "aws_subnet" "gwlbe" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 2 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-gwlbe-${count.index}"
  }
}
resource "aws_subnet" "fw_gwlb" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 4 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-gwlb-${count.index}"
  }
}
resource "aws_subnet" "mgmt" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 6 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-mgmt-${count.index}"
  }
}
resource "aws_subnet" "untrust" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, 8 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-fw-untrust-${count.index}"
  }
}

resource "aws_vpc_endpoint" "this" {
  count = length(var.availability_zones)

  subnet_ids        = [aws_subnet.gwlbe[count.index].id]
  vpc_id            = aws_vpc.this.id
  service_name      = aws_vpc_endpoint_service.this.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    # Workaround for error "InvalidParameter: Endpoint must be removed from route table before deletion".
    create_before_destroy = true
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
resource "aws_route" "tgwa_dg" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.tgwa[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.this[count.index].id
}

resource "aws_route_table" "gwlbe" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-gwlbe-rt"
  }
}
resource "aws_route_table_association" "gwlbe" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.gwlbe[count.index].id
  route_table_id = aws_route_table.gwlbe.id
}
resource "aws_route" "gwlbe_dg" {
  route_table_id         = aws_route_table.gwlbe.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
}

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
resource "aws_route" "fw_dg" {
  route_table_id         = aws_route_table.fw.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-fw-mgmt"
  }
}
resource "aws_route_table_association" "mgmt" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.fw.id
}
resource "aws_route" "mgmt_dg" {
  route_table_id         = aws_route_table.mgmt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
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
