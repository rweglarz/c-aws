locals {
  panorama1_ip   = cidrhost(aws_subnet.mgmt[0].cidr_block, 78)
  panorama1_ipv6 = cidrhost(aws_subnet.mgmt[0].ipv6_cidr_block, 78)
  panorama2_ip   = cidrhost(aws_subnet.mgmt[1].cidr_block, 28)
  panorama3_ip   = cidrhost(aws_subnet.mgmt[1].cidr_block, 30)
}

resource "aws_instance" "panorama1" {
  ami           = data.aws_ami.panorama.id
  instance_type = "m5.4xlarge"
  subnet_id     = resource.aws_subnet.mgmt[0].id
  vpc_security_group_ids = [
    resource.aws_security_group.mgmt.id,
    resource.aws_security_group.panorama.id,
  ]
  key_name       = var.key_pair
  private_ip     = local.panorama1_ip
  ipv6_addresses = [local.panorama1_ipv6]
  tags = {
    Name = "${var.name}-panorama-1",
    tag1 = "v1",
    tag2 = "v2",
  }
  lifecycle {
    ignore_changes = [
      ami,
      instance_type,
    ]
  }
}
resource "aws_instance" "panorama2" {
  ami           = data.aws_ami.panorama.id
  instance_type = "m5.4xlarge"
  subnet_id     = resource.aws_subnet.mgmt[1].id
  vpc_security_group_ids = [
    resource.aws_security_group.mgmt.id,
    resource.aws_security_group.panorama.id,
  ]
  key_name   = var.key_pair
  private_ip = local.panorama2_ip
  tags = {
    Name = "${var.name}-panorama-2",
    tag1 = "v1",
    tag2 = "v2",
  }
  lifecycle {
    ignore_changes = [
      ami,
      instance_type,
    ]
  }
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = resource.aws_subnet.mgmt[0].id
  vpc_security_group_ids = [resource.aws_security_group.mgmt.id]
  key_name               = var.key_pair
  private_ip             = cidrhost(aws_subnet.mgmt[0].cidr_block, 22)
  iam_instance_profile   = "cicd"
  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
  tags = {
    Name = "${var.name}-jumphost"
  }
}
