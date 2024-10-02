module "vpc-sec" {
  source = "../modules/vpc"

  name = "${var.name}-sec"

  cidr_block              = var.sec_cidr
  public_mgmt_prefix_list = module.pl-mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = true

  connect_tgw                    = true
  transit_gateway_id             = aws_ec2_transit_gateway.tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sec.id

  gwlb_service_name = module.gwlb.endpoint_service.service_name

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


module "gwlb" {
  source  = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/gwlb?ref=v2.0.15"

  name    = var.name
  vpc_id  = module.vpc-sec.vpc.id
  subnets = {
    (var.availability_zones[0]) = { id = module.vpc-sec.subnets.gwlb-a.id }
    (var.availability_zones[1]) = { id = module.vpc-sec.subnets.gwlb-b.id }
  }
}


module "vm_series_asg" {
  source  = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/asg?ref=v2.0.15"

  ssh_key_name                    = var.key_pair
  region                          = var.region
  name_prefix                     = var.name
  global_tags                     = {
    t = "rwe"
  }
  vmseries_version                = var.fw_version

  fw_license_type       = var.fw_license_type
  vmseries_product_code = var.vmseries_product_code

  max_size                        = 2
  min_size                        = 0
  desired_capacity                = 1
  lambda_execute_pip_install_once = true
  vmseries_iam_instance_profile   = "main-pan_gwlb"
  subnet_ids                      = [
    module.vpc-sec.subnets.lambda-a.id,
    module.vpc-sec.subnets.lambda-b.id,
  ]
  security_group_ids              = [
    module.vpc-sec.sg_open_id,
  ]
  interfaces = {
    prv = {
      device_index       = 0
      security_group_ids = [ module.vpc-sec.sg_open_id ]
      source_dest_check  = true
      subnet_id          = {
        (var.availability_zones[0]) = module.vpc-sec.subnets.fwprv-a.id
        (var.availability_zones[1]) = module.vpc-sec.subnets.fwprv-b.id
      }
      create_public_ip   = false
    }
    mgmt = {
      device_index       = 1
      # only first is really applied
      security_group_ids = [ module.vpc-sec.sg_open_id ]
      source_dest_check  = true
      subnet_id          = {
        (var.availability_zones[0]) = module.vpc-sec.subnets.mgmt-a.id
        (var.availability_zones[1]) = module.vpc-sec.subnets.mgmt-b.id
      }
      create_public_ip   = false
    }
    pub = {
      device_index       = 2
      security_group_ids = [ module.vpc-sec.sg_open_id ]
      source_dest_check  = true
      subnet_id          = {
        (var.availability_zones[0]) = module.vpc-sec.subnets.fwpub-a.id
        (var.availability_zones[1]) = module.vpc-sec.subnets.fwpub-b.id
      }
      create_public_ip   = false
    }
  }
  target_group_arn  = module.gwlb.target_group.arn
  bootstrap_options = join("\n", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )))

  # scaling_plan_enabled         = each.value.scaling_plan.enabled
  # scaling_metric_name          = each.value.scaling_plan.metric_name
  # scaling_target_value         = each.value.scaling_plan.target_value
  # scaling_statistic            = each.value.scaling_plan.statistic
  # scaling_cloudwatch_namespace = each.value.scaling_plan.cloudwatch_namespace
  # scaling_tags                 = merge(each.value.scaling_plan.tags, { prefix : var.name_prefix })
}
