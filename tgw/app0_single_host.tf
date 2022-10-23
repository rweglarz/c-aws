module "vpc-app0" {
  source = "../modules/vpc"

  name = "${var.name}-app0"

  cidr_block              = var.app0_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = true

  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa_a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "app0_a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_instance" "app0_app0" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc-app0.sg_public_id,
    module.vpc-app0.sg_private_id,
  ]
  subnet_id = module.vpc-app0.subnets["app0_a"].id

  private_ip                  = cidrhost(module.vpc-app0.subnets["app0_a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app0"
  }
}

resource "aws_route_table_association" "app0_sn" {
  route_table_id = module.vpc-app0.route_tables["pfx_via_igw"]
  subnet_id      = module.vpc-app0.subnets["app0_a"].id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "app0_to_mgmt" {
  transit_gateway_attachment_id  = module.vpc-app0.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "app0_to_sec" {
  transit_gateway_attachment_id  = module.vpc-app0.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.mfw.aws_ec2_transit_gateway_route_table_id
}
resource "aws_route" "app0-in-mgmt" {
  route_table_id         = data.terraform_remote_state.mgmt.outputs.aws_route_table_mgmt_id
  destination_cidr_block = module.vpc-app0.vpc.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}


output "app0_ip" {
  value = aws_instance.app0_app0.public_ip
}
