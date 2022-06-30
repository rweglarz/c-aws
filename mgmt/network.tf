resource "aws_vpc" "mgmt" {
  cidr_block                       = var.mgmt_cidr
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.name}-mgmt"
  }
}

resource "aws_subnet" "mgmt" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.mgmt.id
  cidr_block        = cidrsubnet(aws_vpc.mgmt.cidr_block, 1, 0 + count.index)
  ipv6_cidr_block   = cidrsubnet(aws_vpc.mgmt.ipv6_cidr_block, 8, 0 + count.index)
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
resource "aws_route" "mgmt-dg-ipv6" {
  route_table_id              = aws_route_table.mgmt.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.mgmt.id
}


resource "aws_security_group" "mgmt" {
  vpc_id      = aws_vpc.mgmt.id
  name        = "${var.name}-mgmt-pub"
  description = "public mgmt traffic"

  ingress {
    description = "ping"
    from_port   = -1
    to_port     = -1
    protocol    = 1
    cidr_blocks = ["172.16.0.0/12"]
  }
  ingress {
    description = "user id redistribution"
    from_port   = 5007
    to_port     = 5007
    protocol    = 6
    cidr_blocks = ["172.16.0.0/12"]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [aws_ec2_managed_prefix_list.mgmt_ips.id]
    description     = "corporate ips"
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [aws_ec2_managed_prefix_list.tmp_ips.id]
    description     = "temp ips"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-mgmt-pub"
  }
}
resource "aws_security_group" "panorama" {
  description = "panorama traffic"
  vpc_id      = aws_vpc.mgmt.id
  name        = "${var.name}-panorama"

  ingress {
    description = "ping"
    from_port   = -1
    to_port     = -1
    protocol    = 1
    cidr_blocks = ["172.16.0.0/12"]
  }
  ingress {
    description = "panorama"
    from_port   = 3978
    to_port     = 3978
    protocol    = 6
    cidr_blocks = ["172.16.0.0/12"]
    prefix_list_ids = [aws_ec2_managed_prefix_list.csp_nat_ips.id]
  }
  ingress {
    description = "dlsrvr"
    from_port   = 28443
    to_port     = 28443
    protocol    = 6
    cidr_blocks = ["172.16.0.0/12"]
    prefix_list_ids = [aws_ec2_managed_prefix_list.csp_nat_ips.id]
  }
  ingress {
    description = "ha"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "${local.panorama1_ip}/32",
      "${local.panorama2_ip}/32",
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-panorama"
  }
}

resource "aws_eip" "panorama1" {
  instance = aws_instance.panorama1.id
  tags = {
    Name = "${var.name}-panorama1"
  }
}
resource "aws_eip" "panorama2" {
  instance = aws_instance.panorama2.id
  tags = {
    Name = "${var.name}-panorama2"
  }
}
resource "aws_eip" "jumphost" {
  instance = aws_instance.jumphost.id
  tags = {
    Name = "${var.name}-jumphost"
  }
}


