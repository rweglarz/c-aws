module "vpc_app01" {
  source = "../modules/vpc"

  name = "${var.name}-app01"

  cidr_block              = cidrsubnet(var.app0_cidr, 1, 0)
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_private[0].id : null
  public_mgmt_prefix_list = var.pl-mgmt_ips

  deploy_igw       = true
  connect_tgw      = true
  routing_scenario = 1

  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 2, "zone" : var.availability_zones[0] },
  }
}

module "vpc_app02" {
  source = "../modules/vpc"

  name = "${var.name}-app02"

  cidr_block              = cidrsubnet(var.app0_cidr, 1, 1)
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_private[0].id : null
  public_mgmt_prefix_list = var.pl-mgmt_ips

  deploy_igw       = true
  connect_tgw      = true
  routing_scenario = 1

  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id

  subnets = {
    "tgwa-a"     : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-a" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}


module "vm_app01" {
  source = "../modules/linux"

  name          = "${var.name}-app01"
  key_name      = var.key_pair

  subnet_id           = module.vpc_app01.subnets.workload-a.id
  private_ip          = cidrhost(module.vpc_app01.subnets.workload-a.cidr_block, 5)
  associate_public_ip = true

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_app01.security_group_ids.public_mgmt,
    module.vpc_app01.security_group_ids.private,
    module.vpc_app01.security_group_ids.outbound,
  ]
}

module "vm_app02" {
  source = "../modules/linux"

  name          = "${var.name}-app02"
  key_name      = var.key_pair

  subnet_id           = module.vpc_app02.subnets.workload-a.id
  private_ip          = cidrhost(module.vpc_app02.subnets.workload-a.cidr_block, 5)
  associate_public_ip = true

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_app02.security_group_ids.public_mgmt,
    module.vpc_app02.security_group_ids.private,
    module.vpc_app02.security_group_ids.outbound,
  ]
}




resource "aws_ec2_transit_gateway_route_table_propagation" "app01_to_sec" {
  transit_gateway_attachment_id  = module.vpc_app01.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "app02_to_sec" {
  transit_gateway_attachment_id  = module.vpc_app02.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id
}



resource "aws_route53_record" "app0" {
  for_each = {
    app01 = module.vm_app01.public_ip
    app02 = module.vm_app02.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}

output "ipv6_cidr_app0" {
  value = var.dual_stack ? {
    app01 = module.vpc_app01.vpc.ipv6_cidr_block
    app02 = module.vpc_app02.vpc.ipv6_cidr_block
  } : {}
}
