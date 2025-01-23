locals {
  cidr = {
    prod_us_east        = cidrsubnet(var.cidr, 8, 11)
    prod_eu_west        = cidrsubnet(var.cidr, 8, 12)
    prod_eu_central     = cidrsubnet(var.cidr, 8, 13)
    dev_us_east         = cidrsubnet(var.cidr, 8, 21)
    dev_eu_west         = cidrsubnet(var.cidr, 8, 22)
    dev_eu_central      = cidrsubnet(var.cidr, 8, 23)
    security_us_east    = cidrsubnet(var.cidr, 8, 251)
    security_eu_west    = cidrsubnet(var.cidr, 8, 252)
    security_eu_central = cidrsubnet(var.cidr, 8, 253)
  }
}