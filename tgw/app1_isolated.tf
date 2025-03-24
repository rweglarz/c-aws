module "vpc_app11" {
  source = "../modules/vpc"

  name = "${var.name}-app11"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt_ips
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_public[0].id : null

  deploy_igw       = true
  connect_tgw      = false
  routing_scenario = 2

  gwlb_service_name = module.mfw.vpc_endpoint_service_name

  subnets = merge(
    {
      "workload-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
      "gwlbe-a"    : { "idx" : 1, "zone" : var.availability_zones[0], tags = { pan_zone: "env1" } },
    }, 
    var.dual_stack ? {
      "workload-b" : { "idx" : 2, "zone" : var.availability_zones[1], ipv6_native=true },
      "gwlbe-b"    : { "idx" : 3, "zone" : var.availability_zones[1], ipv6_native=true },
    } : {}
  )
}


module "vpc_app12" {
  source = "../modules/vpc"

  name = "${var.name}-app12"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt_ips
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_public[0].id : null

  deploy_igw       = true
  connect_tgw      = false
  routing_scenario = 2

  gwlb_service_name = module.mfw.vpc_endpoint_service_name

  subnets = {
    "workload-b" : { "idx" : 0, "zone" : var.availability_zones[1] },
    "gwlbe-b"    : { "idx" : 1, "zone" : var.availability_zones[1], tags = { pan_zone: "env2" } },
  }
  tags = {
    pan_zone = "overlapping001a"
  }
}



module "vm_app11" {
  source = "../modules/linux"

  name          = "${var.name}-app11"
  key_name      = var.key_pair

  subnet_id           = module.vpc_app11.subnets.workload-a.id
  private_ip          = cidrhost(module.vpc_app11.subnets.workload-a.cidr_block, 5)
  associate_public_ip = true

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_app11.security_group_ids.public_mgmt,
    module.vpc_app11.security_group_ids.local_vpc,
    module.vpc_app11.security_group_ids.outbound,
  ]
}


module "vm_app11d" {
  count = var.dual_stack ? 1 : 0
  source = "../modules/linux"

  name          = "${var.name}-app11b"
  key_name      = var.key_pair

  subnet_id           = module.vpc_app11.subnets.workload-b.id
  instance_type       = "a1.medium" # ipv6 nitro
  associate_public_ip = false

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_app11.security_group_ids.public_mgmt,
    module.vpc_app11.security_group_ids.local_vpc,
    module.vpc_app11.security_group_ids.outbound,
  ]
}


module "vm_app12" {
  source = "../modules/linux"

  name          = "${var.name}-app12"
  key_name      = var.key_pair

  subnet_id           = module.vpc_app12.subnets.workload-b.id
  private_ip          = cidrhost(module.vpc_app12.subnets.workload-b.cidr_block, 5)
  associate_public_ip = true

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_app12.security_group_ids.public_mgmt,
    module.vpc_app12.security_group_ids.local_vpc,
    module.vpc_app12.security_group_ids.outbound,
  ]
}



resource "aws_route53_record" "app1" {
  for_each = {
    app11 = module.vm_app11.public_ip
    app12 = module.vm_app12.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}

output "ipv6_cidr_app1" {
  value = var.dual_stack ? {
    app11 = module.vpc_app11.vpc.ipv6_cidr_block
    app12 = module.vpc_app12.vpc.ipv6_cidr_block
  } : {}
}
