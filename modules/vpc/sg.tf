resource "aws_security_group" "public" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-public"
  description = "public mgmt traffic"

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_vpc_security_group_ingress_rule"  "public_ingress" {
  security_group_id = aws_security_group.public.id
  prefix_list_id    = var.public_mgmt_prefix_list
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule"  "public_egress" {
  security_group_id = aws_security_group.public.id
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule"  "public_egress_ipv6" {
  security_group_id = aws_security_group.public.id
  ip_protocol = "-1"
  cidr_ipv6   = "::/0"
}



resource "aws_security_group" "private" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-private"
  description = "local traffic"
  tags = {
    Name = "${var.name}-local"
  }
}

resource "aws_vpc_security_group_ingress_rule"  "private_ingress" {
  for_each = toset([
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
  ])
  security_group_id = aws_security_group.private.id
  ip_protocol       = "-1"
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_ingress_rule"  "private_ingress_ipv6" {
  security_group_id = aws_security_group.private.id
  ip_protocol       = "-1"
  cidr_ipv6         = "fd00::/8"
}

resource "aws_vpc_security_group_egress_rule"  "private_egress" {
  security_group_id = aws_security_group.private.id
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule"  "private_egress_ipv6" {
  security_group_id = aws_security_group.private.id
  ip_protocol = "-1"
  cidr_ipv6   = "::/0"
}



resource "aws_security_group" "open" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-open"
  description = "all traffic"

  tags = {
    Name = "${var.name}-open"
  }
}

resource "aws_vpc_security_group_ingress_rule"  "open_ingress" {
  security_group_id = aws_security_group.open.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule"  "open_ingress_ipv6" {
  security_group_id = aws_security_group.open.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule"  "open_egress" {
  security_group_id = aws_security_group.open.id
    ip_protocol = "-1"
    cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule"  "open_egress_ipv6" {
  security_group_id = aws_security_group.open.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}



resource "aws_security_group" "local_vpc" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-local-vpc"
  description = "local vpc traffic inboun"

  tags = {
    Name = "${var.name}-local-vpc-inbound"
  }
}

resource "aws_vpc_security_group_ingress_rule"  "local_vpc_ingress" {
  security_group_id = aws_security_group.local_vpc.id
  cidr_ipv4         = aws_vpc.this.cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule"  "local_vpc_ingress_ipv6" {
  security_group_id = aws_security_group.local_vpc.id
  cidr_ipv6         = aws_vpc.this.ipv6_cidr_block
  ip_protocol       = "-1"
}



resource "aws_security_group" "managed_devices" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-managed-devices"
  description = "managed-devices"

  tags = {
    Name = "${var.name}-managed-devices"
  }
}

resource "aws_vpc_security_group_ingress_rule"  "managed_devices_ingress" {
  for_each = toset(["3978", "28443"])
  security_group_id = aws_security_group.managed_devices.id
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule"  "managed_devices_egress" {
  security_group_id = aws_security_group.managed_devices.id
  ip_protocol = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
