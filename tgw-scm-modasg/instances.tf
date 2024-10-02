module "l-mgmt" {
  source     = "../modules/linux"
  name       = "${var.name}-mgmt"
  key_name   = var.key_pair
  subnet_id  = module.vpc-mgmt.subnets.workload-a.id
  private_ip = cidrhost(module.vpc-mgmt.subnets.workload-a.cidr_block, 5)
  vpc_security_group_ids = [
    module.vpc-mgmt.sg_private_id,
    module.vpc-mgmt.sg_public_id,
  ]
}

module "l-env1_s1" {
  source     = "../modules/linux"
  name       = "${var.name}-env1-s1"
  key_name   = var.key_pair
  subnet_id  = module.vpc-env1.subnets.workload-a.id
  private_ip = cidrhost(module.vpc-env1.subnets.workload-a.cidr_block, 5)
  vpc_security_group_ids = [
    module.vpc-env1.sg_private_id,
    module.vpc-env1.sg_public_id,
  ]
}

module "l-env2_s1" {
  source     = "../modules/linux"
  name       = "${var.name}-env2-s1"
  key_name   = var.key_pair
  subnet_id  = module.vpc-env2.subnets.workload-a.id
  private_ip = cidrhost(module.vpc-env2.subnets.workload-a.cidr_block, 5)
  vpc_security_group_ids = [
    module.vpc-env2.sg_private_id,
    module.vpc-env2.sg_public_id,
  ]
}
