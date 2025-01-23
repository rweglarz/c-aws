data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = {
    dev-us-east         = module.vms_us_east.dev.public_ip
    dev-eu-west         = module.vms_eu_west.dev.public_ip
    dev-eu-central      = module.vms_eu_central.dev.public_ip
    prod-us-east        = module.vms_us_east.prod.public_ip
    prod-eu-west        = module.vms_eu_west.prod.public_ip
    prod-eu-central     = module.vms_eu_central.prod.public_ip
    security-us-east    = module.vms_us_east.security.public_ip
    security-eu-west    = module.vms_eu_west.security.public_ip
    security-eu-central = module.vms_eu_central.security.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "cwan-${each.key}"
  type    = "A"
  ttl     = 120
  records = [
    each.value
  ]
}
