resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "this" {
  count  = (var.deploy_igw == true) ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = var.name
  }
}


