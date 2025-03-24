module "vpc_sec" {
  source = "../modules/vpc"

  name = "${var.name}-sec"

  cidr_block              = var.sec_cidr
  ipv6                    = var.dual_stack
  ipv6_ipam_pool_id       = var.dual_stack ? aws_vpc_ipam_pool.ipv6_public[0].id : null
  public_mgmt_prefix_list = var.pl-mgmt_ips
  deploy_igw              = true
  deploy_natgw            = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id

  gwlb_service_name = module.mfw.vpc_endpoint_service_name

  routing_scenario = 9

  subnets = {
    "tgwa-a"   : { "idx" :  0, "zone" : var.availability_zones[0] },
    "tgwa-b"   : { "idx" :  1, "zone" : var.availability_zones[1] },
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


module "bs" {
  count = var.full_bootstrap ? 1 : 0
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/bootstrap?ref=v2.1.0"

  bootstrap_options = local.base_bootstrap
  create_iam_role_policy = false
  iam_role_name = "main-pan_gwlb"
}

locals {
  base_bootstrap = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_pub"],
    var.bootstrap_options["gwlb"],
    # var.bootstrap_options["redis"],
  )
  fw_bootstrap = var.full_bootstrap ? {
    vmseries-bootstrap-aws-s3bucket = module.bs[0].bucket_name
    mgmt-interface-swap             = "enable"
  } : local.base_bootstrap
}

module "mfw" {
  source = "../modules/gwlb_asg_fw"

  name                 = "${var.name}-mfw"
  dual_stack           = var.dual_stack
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type
  iam_instance_profile = data.terraform_remote_state.mgmt.outputs.instance_profile-pan_gwlb
  key_pair             = var.key_pair
  desired_capacity = 0
  target_failover  = var.target_failover

  bootstrap_options         = local.fw_bootstrap
  health_check_grace_period = var.full_bootstrap ? 2100 : null

  vpc_id = module.vpc_sec.vpc.id
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
  value = "awsscg m-mfw 2"
}
