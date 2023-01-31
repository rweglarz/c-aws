resource "aws_instance" "jumphost" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = module.vpc_eks.subnets["mgmt"].id
  vpc_security_group_ids = [module.vpc_eks.sg_public_id]
  key_name               = var.key_name

  private_ip                  = cidrhost(module.vpc_eks.subnets["mgmt"].cidr_block, 5)
  associate_public_ip_address = true

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
  tags = {
    Name = "${var.name}-jumphost"
  }
}
