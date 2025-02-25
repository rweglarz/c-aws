module "vpc-app01" {
  source = "../modules/vpc"

  name = "${var.name}-app01"

  cidr_block              = cidrsubnet(var.app0_cidr, 1, 0)
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = true
  routing_scenario = 1

  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

module "vpc-app02" {
  source = "../modules/vpc"

  name = "${var.name}-app02"

  cidr_block              = cidrsubnet(var.app0_cidr, 1, 1)
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = true
  routing_scenario = 1

  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}



resource "aws_instance" "app01_workload" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc-app01.sg_public_id,
    module.vpc-app01.sg_private_id,
  ]
  subnet_id = module.vpc-app01.subnets["workload-a"].id

  private_ip                  = cidrhost(module.vpc-app01.subnets["workload-a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app01"
  }
}

resource "aws_instance" "app02_workload" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc-app02.sg_public_id,
    module.vpc-app02.sg_private_id,
  ]
  subnet_id = module.vpc-app02.subnets["workload-a"].id

  private_ip                  = cidrhost(module.vpc-app02.subnets["workload-a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app02"
  }
}



resource "aws_ec2_transit_gateway_route_table_propagation" "app01_to_mgmt" {
  transit_gateway_attachment_id  = module.vpc-app01.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "app01_to_sec" {
  transit_gateway_attachment_id  = module.vpc-app01.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.mfw.aws_ec2_transit_gateway_route_table_id
}


resource "aws_ec2_transit_gateway_route_table_propagation" "app02_to_mgmt" {
  transit_gateway_attachment_id  = module.vpc-app02.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "app02_to_sec" {
  transit_gateway_attachment_id  = module.vpc-app02.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.mfw.aws_ec2_transit_gateway_route_table_id
}



resource "aws_route53_record" "app0" {
  for_each = {
    app01 = aws_instance.app01_workload.public_ip 
    app02 = aws_instance.app02_workload.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}
