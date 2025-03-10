data "aws_ami" "pa_vm" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["6njl1pau431dv1qxipg63mvah"]
  }
  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
}

resource "aws_placement_group" "this" {
  name         = var.name
  strategy     = "spread"
  spread_level = "rack"
}

