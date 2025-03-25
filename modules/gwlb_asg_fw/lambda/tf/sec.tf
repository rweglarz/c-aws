module "vpc_sec" {
  source = "../../../vpc"

  name = "${var.name}-sec"

  cidr_block              = var.sec_cidr
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_public.id : null
  public_mgmt_prefix_list = var.pl-mgmt_ips
  deploy_igw              = true
  deploy_natgw            = true

  connect_tgw             = false

  gwlb_service_name = module.mfw.vpc_endpoint_service_name

  routing_scenario = 9

  subnets = {
    "lambda-a" : { "idx" :  2, "zone" : var.availability_zones[0] },
    "lambda-b" : { "idx" :  3, "zone" : var.availability_zones[1] },
    "gwlb-a"   : { "idx" :  4, "zone" : var.availability_zones[0] },
    "gwlb-b"   : { "idx" :  5, "zone" : var.availability_zones[1] },
    "mgmt-a"   : { "idx" :  6, "zone" : var.availability_zones[0] },
    "mgmt-b"   : { "idx" :  7, "zone" : var.availability_zones[1] },
    "fwprv-a"  : { "idx" :  8, "zone" : var.availability_zones[0] },
    "fwprv-b"  : { "idx" :  9, "zone" : var.availability_zones[1] },
    "fwpub-a"  : { "idx" : 10, "zone" : var.availability_zones[0] },
    "fwpub-b"  : { "idx" : 11, "zone" : var.availability_zones[1] },
    "gwlbe-a"  : { "idx" : 12, "zone" : var.availability_zones[0] },
    "gwlbe-b"  : { "idx" : 13, "zone" : var.availability_zones[1] },
    "natgw-a"  : { "idx" : 14, "zone" : var.availability_zones[0] },
    "natgw-b"  : { "idx" : 15, "zone" : var.availability_zones[1] },
  }
}



module "mfw" {
  source = "../../"

  name                 = "${var.name}-mfw"
  fw_instance_type     = var.fw_instance_type
  fw_ami_id            = data.aws_ami.ubuntu.id
  key_pair             = var.key_pair
  bootstrap_options = {}

  max_size         = 10
  desired_capacity = 0

  vpc_id = module.vpc_sec.vpc.id
  dual_stack = var.dual_stack
  reuse_public_ips = var.reuse_public_ips


  gwlb_subnet_ids   = [for k,v in module.vpc_sec.subnets: v.id if strcontains(k, "gwlb-")]
  # lambda_subnet_ids = [for k,v in module.vpc_sec.subnets: v.id if strcontains(k, "lambda-")]
  interfaces = {
    prv = {
      device_index = 0
      security_group_ids = [
        module.vpc_sec.security_group_ids.local_vpc,
        module.vpc_sec.security_group_ids.outbound,
      ]
      subnet_id = { for k,v in module.vpc_sec.subnets: v.availability_zone => v.id if strcontains(k, "fwprv-") }
      associate_public_ip = false
    }
    mgmt = {
      device_index = 1
      security_group_ids = [
        module.vpc_sec.security_group_ids.public_mgmt,
        module.vpc_sec.security_group_ids.private,
        module.vpc_sec.security_group_ids.outbound,
      ]
      subnet_id = { for k,v in module.vpc_sec.subnets: v.availability_zone => v.id if strcontains(k, "mgmt-") }
      associate_public_ip = false
    }
    pub = {
      device_index       = 2
      security_group_ids = [
        module.vpc_sec.security_group_ids.outbound,
      ]
      subnet_id = { for k,v in module.vpc_sec.subnets: v.availability_zone => v.id if strcontains(k, "fwpub-") }
      associate_public_ip = true
    }
  }
}


output "scale_it_out" {
  value = "awsscg ${var.name}-mfw 2"
}
