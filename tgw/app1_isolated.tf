data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-${var.ubuntu_version}-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}


module "vpc-app1" {
  source = "../modules/vpc"

  name = "${var.name}-app1"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = false

  subnets = {
    "app1_a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "vpce_a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_vpc_endpoint" "app1" {
  subnet_ids        = [module.vpc-app1.subnets["vpce_a"].id]
  vpc_id            = module.vpc-app1.vpc.id
  service_name      = module.mfw.aws_vpc_endpoint_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    pan_zone = "mapped001"
  }
}



resource "aws_instance" "app1_app1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  vpc_security_group_ids = [module.vpc-app1.sg_public_id]
  subnet_id              = module.vpc-app1.subnets["app1_a"].id

  private_ip                  = cidrhost(module.vpc-app1.subnets["app1_a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app1"
  }
}


resource "aws_route_table" "app1_igw" {
  vpc_id = module.vpc-app1.vpc.id
  tags = {
    Name = "${var.name}-app1-igw"
  }
}
resource "aws_route_table_association" "app1_igw" {
  gateway_id     = module.vpc-app1.internet_gateway_id
  route_table_id = aws_route_table.app1_igw.id
}
resource "aws_route" "app1_igw-sn" {
  route_table_id         = aws_route_table.app1_igw.id
  destination_cidr_block = module.vpc-app1.subnets["app1_a"].cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.app1.id
}


resource "aws_route_table" "app1_sn" {
  vpc_id = module.vpc-app1.vpc.id
  tags = {
    Name = "${var.name}-app1-sn"
  }
}
resource "aws_route_table_association" "app1_sn" {
  route_table_id = aws_route_table.app1_sn.id
  subnet_id      = module.vpc-app1.subnets["app1_a"].id
}
resource "aws_route" "app1_sn-dg" {
  route_table_id         = aws_route_table.app1_sn.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.app1.id
}

resource "aws_route_table_association" "app1_vpce" {
  route_table_id = module.vpc-app1.route_tables["via_igw"]
  subnet_id      = module.vpc-app1.subnets["vpce_a"].id
}
