data "aws_key_pair" "key_name" {
  filter {
    name   = "key-name"
    values = ["rweglarz*"]
  }
}


resource "aws_network_interface" "attacker" {
  subnet_id       = module.vpc-attacker.subnets["attk"].id
  private_ips     = [cidrhost(module.vpc-attacker.subnets["attk"].cidr_block, 5)]
  security_groups = [
    module.vpc-attacker.sg_private_id,
    module.vpc-attacker.sg_public_id,
  ]
  tags = {
    Name = "${var.name}-attacker"
  }
}
resource "aws_instance" "attacker" {
  ami           = data.aws_ami.latest_ecs.id
  instance_type = "t2.micro"
  user_data     = file("i_attacker.sh")
  key_name      = data.aws_key_pair.key_name.key_name
  network_interface {
    network_interface_id = aws_network_interface.attacker.id
    device_index         = 0
  }

  tags = {
    Name = "${var.name}-attacker"
  }
}
resource "aws_eip" "attacker" {
  instance = aws_instance.attacker.id
}

resource "aws_network_interface" "victim" {
  subnet_id   = module.vpc-victim.subnets["vict"].id
  private_ips = [cidrhost(module.vpc-victim.subnets["vict"].cidr_block, 5)]
  security_groups = [
    module.vpc-victim.sg_private_id,
    module.vpc-victim.sg_public_id,
  ]
  tags = {
    Name = "${var.name}-victim"
  }
}
resource "aws_instance" "victim" {
  ami           = data.aws_ami.latest_ecs.id
  instance_type = "t2.micro"
  user_data     = file("i_victim.sh")
  key_name      = data.aws_key_pair.key_name.key_name
  network_interface {
    network_interface_id = aws_network_interface.victim.id
    device_index         = 0
  }

  tags = {
    Name = "${var.name}-victim"
  }
}
resource "aws_eip" "victim" {
  instance = aws_instance.victim.id
}

output "attacker" {
  value = aws_eip.attacker.address
}
