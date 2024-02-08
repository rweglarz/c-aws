module "vpc-ha2z" {
  source = "../modules/vpc"

  name = "${var.name}-ha2z"

  cidr_block              = var.ha2z_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips
}


resource "aws_subnet" "ha2z_a" {
  for_each          = var.subnets
  vpc_id            = module.vpc-ha2z.vpc.id
  cidr_block        = cidrsubnet(module.vpc-ha2z.vpc.cidr_block, 4, 0 + each.value.index * 2)
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "${var.name}-ha2z_a-${each.key}"
  }
}
resource "aws_subnet" "ha2z_b" {
  for_each          = var.subnets
  vpc_id            = module.vpc-ha2z.vpc.id
  cidr_block        = cidrsubnet(module.vpc-ha2z.vpc.cidr_block, 4, 1 + each.value.index * 2)
  availability_zone = var.availability_zones[1]
  tags = {
    Name = "${var.name}-ha2z_b-${each.key}"
  }
}



module "ha2z_client1" {
  source = "../modules/linux"

  name          = "${var.name}-ha2z_client1"
  instance_type = var.linux_instance_type
  key_name      = var.key_pair

  subnet_id  = aws_subnet.ha2z_a["client1"].id
  private_ip = cidrhost(aws_subnet.ha2z_a["client1"].cidr_block, 10)
  vpc_security_group_ids = [
    module.vpc-ha2z.sg_public_id,
    module.vpc-ha2z.sg_private_id,
  ]
}

module "ha2z_client2" {
  source = "../modules/linux"

  name          = "${var.name}-ha2z_client2"
  instance_type = var.linux_instance_type
  key_name      = var.key_pair

  subnet_id  = aws_subnet.ha2z_b["client2"].id
  private_ip = cidrhost(aws_subnet.ha2z_b["client2"].cidr_block, 10)
  vpc_security_group_ids = [
    module.vpc-ha2z.sg_public_id,
    module.vpc-ha2z.sg_private_id,
  ]
}



module "fw-ha2z_a" {
  source = "../modules/vmseries"

  name             = "${var.name}-ha2z_a"
  fw_instance_type = var.fw_instance_type
  fw_version       = var.fw_version

  iam_instance_profile = data.terraform_remote_state.mgmt.outputs.instance_profile-pan_ha-name
  key_pair             = var.key_pair

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["ha2z_a"],
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = aws_subnet.ha2z_a["mgmt"].id
      security_group_ids = [
        module.vpc-ha2z.sg_public_id,
        module.vpc-ha2z.sg_private_id,
      ]
      private_ips = [cidrhost(aws_subnet.ha2z_a["mgmt"].cidr_block, 5)]
    }
    ha2 = {
      device_index = 1
      subnet_id    = aws_subnet.ha2z_a["ha2"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_a["ha2"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-ha2z.sg_private_id,
      ]
    }
    internet = {
      device_index = 2
      public_ip    = true
      subnet_id    = aws_subnet.ha2z_a["internet"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_a["internet"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-ha2z.sg_open_id,
      ]
    }
    prv = {
      device_index = 3
      subnet_id    = aws_subnet.ha2z_a["prv"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_a["prv"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-ha2z.sg_open_id,
      ]
    }
  }
}

module "fw-ha2z_b" {
  source = "../modules/vmseries"

  name             = "${var.name}-ha2z_b"
  fw_instance_type = var.fw_instance_type
  fw_version       = var.fw_version

  iam_instance_profile = data.terraform_remote_state.mgmt.outputs.instance_profile-pan_ha-name
  key_pair             = var.key_pair

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["ha2z_b"],
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = aws_subnet.ha2z_b["mgmt"].id
      security_group_ids = [
        module.vpc-ha2z.sg_public_id,
        module.vpc-ha2z.sg_private_id,
      ]
      private_ips = [cidrhost(aws_subnet.ha2z_b["mgmt"].cidr_block, 6)]
    }
    ha2 = {
      device_index = 1
      subnet_id    = aws_subnet.ha2z_b["ha2"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_b["ha2"].cidr_block, 6)]
      security_group_ids = [
        module.vpc-ha2z.sg_private_id,
      ]
    }
    internet = {
      device_index = 2
      public_ip    = false
      subnet_id    = aws_subnet.ha2z_b["internet"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_b["internet"].cidr_block, 6)]
      security_group_ids = [
        module.vpc-ha2z.sg_open_id,
      ]
    }
    prv = {
      device_index = 3
      subnet_id    = aws_subnet.ha2z_b["prv"].id
      private_ips  = [cidrhost(aws_subnet.ha2z_b["prv"].cidr_block, 6)]
      security_group_ids = [
        module.vpc-ha2z.sg_open_id,
      ]
    }
  }
}

output "ha2z_a" {
  value = module.fw-ha2z_a.public_ips
}

output "ha2z_b" {
  value = module.fw-ha2z_b.public_ips
}



resource "aws_route_table" "ha2z-client" {
  vpc_id = module.vpc-ha2z.vpc.id
  tags = {
    Name = "${var.name}-ha2z-client"
  }
}
resource "aws_route_table_association" "ha2z-client1" {
  subnet_id      = aws_subnet.ha2z_a["client1"].id
  route_table_id = aws_route_table.ha2z-client.id
}
resource "aws_route_table_association" "ha2z-client2" {
  subnet_id      = aws_subnet.ha2z_b["client2"].id
  route_table_id = aws_route_table.ha2z-client.id
}
resource "aws_route" "ha2z-dg" {
  route_table_id         = aws_route_table.ha2z-client.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.fw-ha2z_a.eni["prv"]
}
resource "aws_route" "ha2z-mgmt" {
  for_each               = { for e in var.mgmt_ips : replace(e.description, " ", "-") => e.cidr }
  route_table_id         = aws_route_table.ha2z-client.id
  destination_cidr_block = each.value
  gateway_id             = module.vpc-ha2z.internet_gateway_id
}
resource "aws_route" "ha2z-client1" {
  route_table_id         = aws_route_table.ha2z-client.id
  destination_cidr_block = aws_subnet.ha2z_a["client1"].cidr_block
  network_interface_id   = module.fw-ha2z_a.eni["prv"]
}
resource "aws_route" "ha2z-client2" {
  route_table_id         = aws_route_table.ha2z-client.id
  destination_cidr_block = aws_subnet.ha2z_b["client2"].cidr_block
  network_interface_id   = module.fw-ha2z_a.eni["prv"]
}



resource "aws_route_table_association" "ha2z_a-mgmt" {
  subnet_id      = aws_subnet.ha2z_a["mgmt"].id
  route_table_id = module.vpc-ha2z.route_tables["via_igw"]
}
resource "aws_route_table_association" "ha2z_b-mgmt" {
  subnet_id      = aws_subnet.ha2z_b["mgmt"].id
  route_table_id = module.vpc-ha2z.route_tables["via_igw"]
}
resource "aws_route_table_association" "ha2z_a-internet" {
  subnet_id      = aws_subnet.ha2z_a["internet"].id
  route_table_id = module.vpc-ha2z.route_tables["via_igw"]
}
resource "aws_route_table_association" "ha2z_b-internet" {
  subnet_id      = aws_subnet.ha2z_b["internet"].id
  route_table_id = module.vpc-ha2z.route_tables["via_igw"]
}


resource "aws_network_acl" "ha2z" {
  vpc_id   = module.vpc-ha2z.vpc.id
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 50
    action     = "deny"
    cidr_block = aws_subnet.ha2z_b["prv"].cidr_block
    icmp_code = -1
    icmp_type = 8
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "ha2z" {
  network_acl_id = aws_network_acl.ha2z.id
  subnet_id      = aws_subnet.ha2z_a["prv"].id
}

