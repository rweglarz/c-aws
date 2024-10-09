module "vpc_sec" {
  source = "../modules/vpc"

  name = "${var.name}-sec"

  cidr_block              = cidrsubnet(var.cidr, 2, 0)
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips[var.region]
  deploy_igw              = false

  connect_tgw                    = false

  subnets = {
    "ngfw-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "ngfw-b" : { "idx" : 1, "zone" : var.availability_zones[1] },
    "ngfw-c" : { "idx" : 2, "zone" : var.availability_zones[2] },
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = var.log_group
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "audit" {
  name = "${var.log_group}-audit"
  retention_in_days = var.log_retention_days
}

resource "cloudngfwaws_ngfw_log_profile" "this" {
  ngfw       = cloudngfwaws_ngfw.this.name
  #account_id = ""
  account_id  = var.account_id
  cloud_watch_metric_namespace  = aws_cloudwatch_log_group.this.name
  log_destination {
    log_type         = "TRAFFIC"
    destination_type = "CloudWatchLogs"
    destination      = aws_cloudwatch_log_group.this.name
  }
  log_destination {
    log_type         = "THREAT"
    destination_type = "CloudWatchLogs"
    destination      = aws_cloudwatch_log_group.this.name
  }
  log_destination {
    log_type         = "DECRYPTION"
    destination_type = "CloudWatchLogs"
    destination      = aws_cloudwatch_log_group.this.name
  }

  cloudwatch_metric_fields = [
    "Dataplane_CPU_Utilization",
    "Dataplane_Packet_Buffer_Utilization",
    "Connection_Per_Second",
		"Session_Throughput_Kbps",
    "Session_Throughput_Pps",
    "Session_Active",
    "Session_Utilization",
		"BytesIn",
    "BytesOut",
    "PktsIn",
    "PktsOut"
  ]
}

resource "cloudngfwaws_ngfw" "this" {
  name        = "${var.name}-ta"
  vpc_id      = module.vpc_sec.vpc.id
  account_id  = var.account_id
  description = "created with tf"

  endpoint_mode = "CustomerManaged"
  multi_vpc     = true

  dynamic "subnet_mapping" {
    for_each = [for s in module.vpc_sec.subnets : s.availability_zone_id if strcontains(s.tags.Name, "-ngfw")]
    content {
      availability_zone_id =  subnet_mapping.value
    }
  }

  rulestack = cloudngfwaws_rulestack.this.name

  depends_on = [ 
    cloudngfwaws_rulestack.this,
    cloudngfwaws_commit_rulestack.this,
  ]
}
