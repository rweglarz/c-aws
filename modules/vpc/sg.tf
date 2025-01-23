resource "aws_security_group" "public" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-public"
  description = "public mgmt traffic"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [var.public_mgmt_prefix_list]
    description     = "public ips"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_security_group" "private" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-private"
  description = "local traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
    description = "all private"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-local"
  }
}

resource "aws_security_group" "open" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-open"
  description = "all traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "all traffic"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-open"
  }
}


resource "aws_security_group" "managed_devices" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-managed-devices"
  description = "managed-devices"

  ingress {
    from_port   = 3978
    to_port     = 3978
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "tcp-3978"
  }
  ingress {
    from_port   = 28443
    to_port     = 28443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "tcp-3978"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-managed-devices"
  }
}
