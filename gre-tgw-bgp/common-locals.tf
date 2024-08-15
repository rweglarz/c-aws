locals {
  asn = {
    tgw  = 4200000000
    fw   = 4200000001
  }
  cidr = {
    tgw = cidrsubnet(var.cidr, 8, 0)
    hub = cidrsubnet(var.cidr, 8, 1)
  }
}
