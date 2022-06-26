locals {
  panorama1_ip   = cidrhost(aws_subnet.mgmt[0].cidr_block, 78)
  panorama2_ip   = cidrhost(aws_subnet.mgmt[1].cidr_block, 28)
}

resource "aws_instance" "panorama1" {
  ami           = data.aws_ami.panorama.id
  instance_type = "m5.2xlarge"
  subnet_id     = resource.aws_subnet.mgmt[0].id
  vpc_security_group_ids = [
    resource.aws_security_group.mgmt.id,
    resource.aws_security_group.panorama.id,
  ]
  key_name       = var.key_pair
  private_ip     = local.panorama1_ip
  tags = {
    Name = "${var.name}-panorama-1"
  }
}
resource "aws_instance" "panorama2" {
  ami           = data.aws_ami.panorama.id
  instance_type = "m5.2xlarge"
  subnet_id     = resource.aws_subnet.mgmt[1].id
  vpc_security_group_ids = [
    resource.aws_security_group.mgmt.id,
    resource.aws_security_group.panorama.id,
  ]
  key_name   = var.key_pair
  private_ip = local.panorama2_ip
  tags = {
    Name = "${var.name}-panorama-2"
  }
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = resource.aws_subnet.mgmt[0].id
  vpc_security_group_ids = [resource.aws_security_group.mgmt.id]
  key_name               = var.key_pair
  private_ip             = cidrhost(aws_subnet.mgmt[0].cidr_block, 22)
  tags = {
    Name = "${var.name}-jumphost"
  }
}
