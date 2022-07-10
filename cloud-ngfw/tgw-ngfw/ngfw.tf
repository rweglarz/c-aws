resource "cloudngfwaws_ngfw_log_profile" "example" {
  ngfw       = cloudngfwaws_ngfw.x.name
  account_id = var.account_id
  log_destination {
    log_type         = "TRAFFIC"
    destination_type = "CloudWatchLogs"
    destination      = "PaloAltoCloudNGFW"
  }
  log_destination {
    log_type         = "THREAT"
    destination_type = "CloudWatchLogs"
    destination      = "PaloAltoCloudNGFW"
  }
  log_destination {
    log_type         = "DECRYPTION"
    destination_type = "CloudWatchLogs"
    destination      = "PaloAltoCloudNGFW"
  }
}

resource "cloudngfwaws_ngfw" "x" {
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
}
