resource "aws_vpc" "mgmt" {
  cidr_block = var.mgmt_cidr
  tags = {
    Name = "${var.name}-mgmt"
  }
}

resource "aws_subnet" "mgmt" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.mgmt.id
  cidr_block        = cidrsubnet(aws_vpc.mgmt.cidr_block, 1, 0+count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-mgmt-subnet-${count.index}"
  }
}
resource "aws_internet_gateway" "mgmt" {
  vpc_id = aws_vpc.mgmt.id
  tags = {
    Name = "${var.name}-mgmt-igw"
  }
}

resource "aws_route_table_association" "mgmt" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.mgmt.id
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.mgmt.id
  tags = {
    Name = "${var.name}-mgmt-rt"
  }
}

resource "aws_route" "mgmt-dg" {
  route_table_id         = aws_route_table.mgmt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mgmt.id
}
resource "aws_route" "mgmt-private" {
  route_table_id         = aws_route_table.mgmt.id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}


resource "aws_security_group" "mgmt" {
  description = "public mgmt traffic"
  vpc_id      = aws_vpc.mgmt.id
  name = "${var.name}-mgmt-pub"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [aws_ec2_managed_prefix_list.mgmt_ips.id]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-mgmt-pub"
  }
}
resource "aws_security_group" "panorama" {
  description = "panorama traffic"
  vpc_id      = aws_vpc.mgmt.id
  name = "${var.name}-panorama"

  ingress {
    from_port       = 3978
    to_port         = 3978
    protocol        = 6
    cidr_blocks     = ["172.16.0.0/12"]
  }
  ingress {
    from_port       = 28443
    to_port         = 28443
    protocol        = 6
    cidr_blocks     = ["172.16.0.0/12"]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = 6
    cidr_blocks     = [
      "${local.panorama1_ip}/32",
      "${local.panorama2_ip}/32",
    ]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-panorama"
  }
}

resource "aws_eip" "panorama1" {
  instance          = aws_instance.panorama1.id
  tags = {
    Name = "${var.name}-panorama1"
  }
}
resource "aws_eip" "panorama2" {
  instance          = aws_instance.panorama2.id
  tags = {
    Name = "${var.name}-panorama2"
  }
}
resource "aws_eip" "jumphost" {
  instance          = aws_instance.jumphost.id
  tags = {
    Name = "${var.name}-jumphost"
  }
}


resource "aws_ec2_transit_gateway_vpc_attachment" "mgmt" {
  vpc_id                                          = aws_vpc.mgmt.id
  subnet_ids                                      = aws_subnet.mgmt[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${var.name}-mgmt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "mgmt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-mgmt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "mgmt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.mgmt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}

resource "aws_ec2_transit_gateway_route" "mgmt-dg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.mgmt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
