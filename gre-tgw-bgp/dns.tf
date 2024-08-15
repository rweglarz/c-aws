data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = {
    gre-tgw-fw1      = module.fw1.mgmt_public_ip
    gre-tgw-fw2      = module.fw2.mgmt_public_ip
    gre-tgw-jumphost = module.jumphost.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 120
  records = [
    each.value
  ]
}
