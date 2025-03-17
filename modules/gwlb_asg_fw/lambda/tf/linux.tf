module "vm_t1" {
  source = "../../../linux"

  name          = "${var.name}-t1"
  key_name      = var.key_pair

  subnet_id  = module.vpc_sec.subnets.mgmt-a.id
  private_ip = cidrhost(module.vpc_sec.subnets.mgmt-a.cidr_block, 5)
  associate_public_ip = false
  source_dest_check   = false

  vpc_security_group_ids = [
    module.vpc_sec.security_group_ids.public_mgmt,
    module.vpc_sec.security_group_ids.private,
  ]
}

output "vm_t1" {
    value = module.vm_t1.id
}
