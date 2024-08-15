module "fw1" {
  source = "../modules/vmseries"

  name     = "${var.name}-fw1"
  key_pair = var.key_pair

  bootstrap_options = merge(
    var.bootstrap_options,
    {
      vm-auth-key = panos_vm_auth_key.this.id
      dgname      = panos_device_group.this.name
      tplname     = panos_panorama_template_stack.fw1.name
    },
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.vpc_hub.subnets.mgmt-a.id
      security_group_ids = [
        module.vpc_hub.sg_public_id,
        module.vpc_hub.sg_private_id,
      ]
      private_ips = [ cidrhost(module.vpc_hub.subnets.mgmt-a.cidr_block, 5) ]
    }
    private = {
      device_index = 1
      subnet_id    = module.vpc_hub.subnets.private-a.id
      public_ip    = true
      private_ips = [ cidrhost(module.vpc_hub.subnets.private-a.cidr_block, 5) ]
      security_group_ids = [
        module.vpc_hub.sg_open_id,
      ]
    }
  }
}

module "fw2" {
  source = "../modules/vmseries"

  name     = "${var.name}-fw2"
  key_pair = var.key_pair

  bootstrap_options = merge(
    var.bootstrap_options,
    {
      vm-auth-key = panos_vm_auth_key.this.id
      dgname      = panos_device_group.this.name
      tplname     = panos_panorama_template_stack.fw2.name
    },
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.vpc_hub.subnets.mgmt-b.id
      security_group_ids = [
        module.vpc_hub.sg_public_id,
        module.vpc_hub.sg_private_id,
      ]
      private_ips = [ cidrhost(module.vpc_hub.subnets.mgmt-b.cidr_block, 5) ]
    }
    private = {
      device_index = 1
      subnet_id    = module.vpc_hub.subnets.private-b.id
      public_ip    = true
      private_ips = [ cidrhost(module.vpc_hub.subnets.private-b.cidr_block, 5) ]
      security_group_ids = [
        module.vpc_hub.sg_open_id,
      ]
    }
  }
}
