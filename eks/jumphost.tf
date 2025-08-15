module "vm_jumphost" {
  source = "../modules/linux"

  name          = "${var.name}-jumphost"
  key_name      = var.key_pair

  subnet_id           = module.vpc_eks.subnets["mgmt"].id
  private_ip          = cidrhost(module.vpc_eks.subnets["mgmt"].cidr_block, 5)
  associate_public_ip = true

  iam_instance_profile = "SSMInstanceProfile"

  vpc_security_group_ids = [
    module.vpc_eks.security_group_ids.public_mgmt,
    module.vpc_eks.security_group_ids.private,
    module.vpc_eks.security_group_ids.outbound,
  ]
}
