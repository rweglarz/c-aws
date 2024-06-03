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
  account_id = var.account_id
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
  name        = "${var.name}-tf"
  vpc_id      = module.vpc-sec.vpc.id
  account_id  = var.account_id
  description = "created with tf"

  endpoint_mode = "ServiceManaged"
  dynamic "subnet_mapping" {
    for_each = [for s in module.vpc-sec.subnets : s.id if length(regexall("-ngfw", s.tags.Name)) > 0]
    content {
      subnet_id = subnet_mapping.value
    }
  }

  rulestack = var.rule_stack
  link_id   = var.link_id
}
