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
    module.vpc-attacker.security_group_ids.public_mgmt,
    module.vpc-attacker.security_group_ids.private,
    module.vpc-attacker.security_group_ids.outbound,
  ]
  tags = {
    Name = "${var.name}-attacker"
  }
}
resource "aws_instance" "attacker" {
  ami           = data.aws_ami.latest_ecs.id
  instance_type = "t2.micro"
  user_data     = file("i_attacker.sh")

  key_name             = data.aws_key_pair.key_name.key_name
  iam_instance_profile = var.iam_instance_profile

  primary_network_interface {
    network_interface_id = aws_network_interface.attacker.id
  }
  lifecycle { ignore_changes = [ ami ] }
  tags = {
    Name = "${var.name}-attacker"
    role = "attacker"
  }
}
resource "aws_eip" "attacker" {
  instance = aws_instance.attacker.id
}

resource "aws_network_interface" "victim" {
  subnet_id   = module.vpc-victim.subnets["vict"].id
  private_ips = [cidrhost(module.vpc-victim.subnets["vict"].cidr_block, 5)]
  security_groups = [
    module.vpc-victim.security_group_ids.public_mgmt,
    module.vpc-victim.security_group_ids.private,
    module.vpc-victim.security_group_ids.outbound,
  ]
  tags = {
    Name = "${var.name}-victim"
  }
}
resource "aws_instance" "victim" {
  ami           = data.aws_ami.latest_ecs.id
  instance_type = "t2.micro"
  user_data     = file("i_victim.sh")

  key_name             = data.aws_key_pair.key_name.key_name
  iam_instance_profile = var.iam_instance_profile

  primary_network_interface {
    network_interface_id = aws_network_interface.victim.id
  }

  lifecycle { ignore_changes = [ ami ] }
  tags = {
    Name = "${var.name}-victim"
    role = "victim"
  }
}
resource "aws_eip" "victim" {
  instance = aws_instance.victim.id
}

output "attacker" {
  value = aws_eip.attacker.address
}


module "client1" {
  source = "../../modules/linux"

  name     = "${var.name}-client1"
  key_name = data.aws_key_pair.key_name.key_name

  subnet_id            = module.vpc-client1.subnets["clnt"].id
  private_ip           = cidrhost(module.vpc-client1.subnets["clnt"].cidr_block, 5)
  associate_public_ip  = true

  iam_instance_profile = var.iam_instance_profile

  vpc_security_group_ids = [
    module.vpc-client1.security_group_ids.public_mgmt,
    module.vpc-client1.security_group_ids.private,
    module.vpc-client1.security_group_ids.outbound,
  ]
  tags = {
    role = "client"
  }
}

module "client2" {
  source = "../../modules/linux"

  name     = "${var.name}-client2"
  key_name = data.aws_key_pair.key_name.key_name

  subnet_id            = module.vpc-client2.subnets["clnt"].id
  private_ip           = cidrhost(module.vpc-client2.subnets["clnt"].cidr_block, 5)
  associate_public_ip  = false

  iam_instance_profile = var.iam_instance_profile

  vpc_security_group_ids = [
    module.vpc-client2.security_group_ids.public_mgmt,
    module.vpc-client2.security_group_ids.private,
    module.vpc-client2.security_group_ids.outbound,
  ]

  tags = {
    role = "client"
  }
}
