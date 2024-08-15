resource "panos_device_group" "this" {
  name = "aws-gre-tgw-bgp"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group_parent" "this" {
  device_group = panos_device_group.this.name
  parent       = "aws vm common"

  lifecycle { create_before_destroy = true }
}
