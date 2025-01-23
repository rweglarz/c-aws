module "vms_eu_central" {
  source = "../modules/linux"
  providers = { aws = aws.eu-central-1 }

  for_each = {
    prod     = module.vpc_eu_central.prod
    dev      = module.vpc_eu_central.dev
    security = module.vpc_eu_central.security
  }

  name          = "${var.name}-${each.key}-eu-central"
  key_name      = var.key_pair

  subnet_id  = each.value.subnets.workload-a.id
  private_ip = cidrhost(each.value.subnets.workload-a.cidr_block, 5)
  associate_public_ip = true
  source_dest_check  = false

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    each.value.security_groups.public_mgmt,
    each.value.security_groups.private,
  ]
}


module "vms_eu_west" {
  source = "../modules/linux"
  providers = { aws = aws.eu-west-1 }
  
  for_each = {
    prod     = module.vpc_eu_west.prod
    dev      = module.vpc_eu_west.dev
    security = module.vpc_eu_west.security
  }

  name          = "${var.name}-${each.key}-eu-west"
  key_name      = var.key_pair

  subnet_id  = each.value.subnets.workload-a.id
  private_ip = cidrhost(each.value.subnets.workload-a.cidr_block, 5)
  associate_public_ip = true
  source_dest_check  = false

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    each.value.security_groups.public_mgmt,
    each.value.security_groups.private,
  ]
}


module "vms_us_east" {
  source = "../modules/linux"
  providers = { aws = aws.us-east-1 }
  
  for_each = {
    prod     = module.vpc_us_east.prod
    dev      = module.vpc_us_east.dev
    security = module.vpc_us_east.security
  }

  name          = "${var.name}-${each.key}-us-east"
  key_name      = var.key_pair

  subnet_id  = each.value.subnets.workload-a.id
  private_ip = cidrhost(each.value.subnets.workload-a.cidr_block, 5)

  associate_public_ip = true
  source_dest_check   = false

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    each.value.security_groups.public_mgmt,
    each.value.security_groups.private,
  ]
}
