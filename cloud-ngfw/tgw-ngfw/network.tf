resource "aws_ec2_transit_gateway" "tgw" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-spoke"
  }
}
resource "aws_ec2_transit_gateway_route_table" "sec" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-sec"
  }
}
resource "aws_ec2_transit_gateway_route" "spoke-dg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.vpc-sec.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "attacker-into-sec" {
  transit_gateway_attachment_id  = module.vpc-attacker.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "victim-into-sec" {
  transit_gateway_attachment_id  = module.vpc-victim.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "client-into-sec" {
  transit_gateway_attachment_id  = module.vpc-client.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}


module "vpc-sec" {
  source = "../../modules/vpc"

  name = "${var.name}-sec"

  cidr_block              = cidrsubnet(var.cidr, 2, 0)
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
  tgw_appliance_mode = true

  subnets = {
    "tgwa-a" : { "idx" : 0, "zone" : var.zones[0] },
    "tgwa-b" : { "idx" : 1, "zone" : var.zones[1] },
    #"tgwa-c" : { "idx" : 2, "zone" : var.zones[2] },
    "ngfw-a" : { "idx" : 3, "zone" : var.zones[0] },
    "ngfw-b" : { "idx" : 4, "zone" : var.zones[1] },
    #"ngfw-c" : { "idx" : 5, "zone" : var.zones[2] },
    "natgw-a"  : { "idx" : 6, "zone" : var.zones[0] },
    "natgw-b"  : { "idx" : 7, "zone" : var.zones[1] },
    #"natgw-c"  : { "idx" : 8, "zone" : var.zones[2] },
  }
}

module "vpc-victim" {
  source = "../../modules/vpc"

  name = "${var.name}-victim"

  cidr_block              = cidrsubnet(var.cidr, 2, 1)
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa" : { "idx" : 0, "zone" : var.zones[0] },
    "vict" : { "idx" : 1, "zone" : var.zones[0] },
  }
}

module "vpc-attacker" {
  source = "../../modules/vpc"

  name = "${var.name}-attacker"

  cidr_block              = cidrsubnet(var.cidr, 2, 2)
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa" : { "idx" : 0, "zone" : var.zones[1] },
    "attk" : { "idx" : 1, "zone" : var.zones[1] },
  }
}

module "vpc-client" {
  source = "../../modules/vpc"

  name = "${var.name}-client"

  cidr_block              = cidrsubnet(var.cidr, 2, 3)
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa" : { "idx" : 0, "zone" : var.zones[0] },
    "clnt" : { "idx" : 1, "zone" : var.zones[0] },
  }
}


resource "aws_route_table_association" "attacker" {
  subnet_id      = module.vpc-attacker.subnets["attk"].id
  route_table_id = module.vpc-attacker.route_tables["via_mixed"]
}
resource "aws_route_table_association" "victim" {
  subnet_id      = module.vpc-victim.subnets["vict"].id
  route_table_id = module.vpc-victim.route_tables["via_mixed"]
}
resource "aws_route_table_association" "client" {
  subnet_id      = module.vpc-client.subnets["clnt"].id
  route_table_id = module.vpc-client.route_tables["pfx_via_igw"]
}


output "vpc-sec" {
  value = module.vpc-sec
}
output "tgw-id" {
  value     =  aws_ec2_transit_gateway.tgw.id
}
