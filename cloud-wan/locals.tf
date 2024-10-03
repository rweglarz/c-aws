locals {
  cidr = {
    prod_eu_central = cidrsubnet(var.cidr, 8, 0)
    prod_eu_west    = cidrsubnet(var.cidr, 8, 1)
  }
}