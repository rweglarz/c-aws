resource "aws_instance" "net-workload-1" {
  provider = aws.network

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc.sg_public_id,
    module.vpc.sg_private_id,
  ]
  subnet_id = module.vpc.subnets.workload-1.id

  private_ip                  = cidrhost(module.vpc.subnets.workload-1.cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-net-workload-1"
  }
}

resource "aws_instance" "account1-workload" {
  provider = aws.account1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    aws_security_group.account1.id
  ]
  subnet_id = module.vpc.subnets.workload-1.id

  private_ip                  = cidrhost(module.vpc.subnets.workload-1.cidr_block, 6)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-account-1-workload-1"
  }
}

output "vms" {
 value = {
  net-workload-1 = aws_instance.net-workload-1.public_ip
  acct1-workload = aws_instance.account1-workload.public_ip
 }
}