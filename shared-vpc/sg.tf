resource "aws_security_group" "account1" {
  provider = aws.account1

  vpc_id      = module.vpc.vpc.id
  name        = "${var.name}-public"
  description = "public mgmt traffic"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = [for p in var.mgmt_ips: p.cidr]
    description     = "public ips"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-account1-public"
  }
}
