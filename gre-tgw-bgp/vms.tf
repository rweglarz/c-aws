module "jumphost" {
  source = "../modules/linux"

  name          = "${var.name}-jumphost"
  key_name      = var.key_pair

  subnet_id  = module.vpc_jumphost.subnets.workload-a.id
  private_ip = cidrhost(module.vpc_jumphost.subnets.workload-a.cidr_block, 5)
  vpc_security_group_ids = [
    module.vpc_jumphost.sg_public_id,
    module.vpc_jumphost.sg_private_id,
  ]
}

module "srv" {
  for_each = local.vpc_env

  source = "../modules/linux"

  name          = "${var.name}-${each.key}"
  key_name      = var.key_pair

  subnet_id  = module.vpc_env[each.key].subnets.workload-a.id
  private_ip = cidrhost(module.vpc_env[each.key].subnets.workload-a.cidr_block, 5)
  associate_public_ip = false

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_env[each.key].sg_public_id,
    module.vpc_env[each.key].sg_private_id,
  ]
}
