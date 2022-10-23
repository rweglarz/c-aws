module "vpc-app5" {
  source = "../modules/vpc"

  name = "${var.name}-app5"

  cidr_block              = var.app5_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw                     = true
  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa_a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "app5_a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_instance" "app5_app5" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc-app5.sg_public_id,
    module.vpc-app5.sg_private_id,
  ]
  subnet_id = module.vpc-app5.subnets["app5_a"].id

  private_ip                  = cidrhost(module.vpc-app5.subnets["app5_a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app5"
  }
}

resource "aws_route_table_association" "app5_sn" {
  route_table_id = module.vpc-app5.route_tables["pfx_via_igw"]
  subnet_id      = module.vpc-app5.subnets["app5_a"].id
}

output "app5_ip" {
  value = aws_instance.app5_app5.public_ip
}
