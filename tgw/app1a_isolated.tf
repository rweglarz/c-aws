module "vpc-app1a" {
  source = "../modules/vpc"

  name = "${var.name}-app1a"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = false

  subnets = {
    "app1" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "vpce" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_vpc_endpoint" "app1a" {
  subnet_ids        = [module.vpc-app1a.subnets["vpce"].id]
  vpc_id            = module.vpc-app1a.vpc.id
  service_name      = module.mfw.aws_vpc_endpoint_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    pan_zone = "overlapping001a"
  }
}



resource "aws_instance" "app1a_app1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  vpc_security_group_ids = [module.vpc-app1a.sg_public_id]
  subnet_id              = module.vpc-app1a.subnets["app1"].id

  private_ip                  = cidrhost(module.vpc-app1a.subnets["app1"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app1"
  }
}


resource "aws_route_table" "app1a_igw" {
  vpc_id = module.vpc-app1a.vpc.id
  tags = {
    Name = "${var.name}-app1a-igw"
  }
}
resource "aws_route_table_association" "app1a_igw" {
  gateway_id     = module.vpc-app1a.internet_gateway_id
  route_table_id = aws_route_table.app1a_igw.id
}
resource "aws_route" "app1a_igw-sn" {
  route_table_id         = aws_route_table.app1a_igw.id
  destination_cidr_block = module.vpc-app1a.subnets["app1"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.app1a.id
}


resource "aws_route_table" "app1a_sn" {
  vpc_id = module.vpc-app1a.vpc.id
  tags = {
    Name = "${var.name}-app1a-sn"
  }
}
resource "aws_route_table_association" "app1a_sn" {
  route_table_id = aws_route_table.app1a_sn.id
  subnet_id      = module.vpc-app1a.subnets["app1"].id
}
resource "aws_route" "app1a_sn-dg" {
  route_table_id         = aws_route_table.app1a_sn.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.app1a.id
}

resource "aws_route_table_association" "app1a_vpce" {
  route_table_id = module.vpc-app1a.route_tables["via_igw"]
  subnet_id      = module.vpc-app1a.subnets["vpce"].id
}
