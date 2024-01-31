resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.asn["aws"]
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [var.tgw_cidr]
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-spokes"
  }
}


resource "aws_customer_gateway" "ha2z" {
  device_name = "ha2z"
  bgp_asn     = var.asn["ha2z"]
  ip_address  = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])
  type        = "ipsec.1"
}

resource "aws_vpn_connection" "ha2z" {
  transit_gateway_id    = aws_ec2_transit_gateway.tgw.id
  customer_gateway_id   = aws_customer_gateway.ha2z.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]
  tunnel1_inside_cidr   = "169.254.6.0/30"
  tunnel2_inside_cidr   = "169.254.6.4/30"
  tunnel1_preshared_key = var.psk
  tunnel2_preshared_key = var.psk
  # tunnel1_dpd_timeout_action = "restart"
  # tunnel2_dpd_timeout_action = "restart"
  tunnel1_startup_action = "start"
  tunnel2_startup_action = "start"
}


resource "aws_ec2_transit_gateway_route_table_association" "vpn_ha2z" {
  transit_gateway_attachment_id  = aws_vpn_connection.ha2z.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_ha2z-spokes" {
  transit_gateway_attachment_id  = aws_vpn_connection.ha2z.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc1-spokes" {
  transit_gateway_attachment_id  = module.vpc-vpc1.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}


module "vpc-vpc1" {
  source = "../modules/vpc"

  name = "${var.name}-vpc1"

  cidr_block              = var.vpc1_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw                     = true
  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id

  subnets = {
    "tgwa_a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "s1_a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_route_table_association" "vpc1-s1_a" {
  subnet_id      = module.vpc-vpc1.subnets["s1_a"].id
  route_table_id = module.vpc-vpc1.route_tables.via_mixed
}

resource "aws_instance" "vpc1_client1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  vpc_security_group_ids = [
    module.vpc-vpc1.sg_public_id,
    module.vpc-vpc1.sg_private_id,
  ]
  subnet_id = module.vpc-vpc1.subnets["s1_a"].id

  private_ip                  = cidrhost(module.vpc-vpc1.subnets["s1_a"].cidr_block, 5)

  tags = {
    Name = "${var.name}-vpc1_client1"
  }
}

resource "aws_eip" "vpc1_client1" {
  instance = aws_instance.vpc1_client1.id
  tags = {
    Name = "${var.name}-vpc1_client1"
  }
}
