data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = {
    ha1z-fw-a = module.fw-ha1z_a.mgmt_public_ip
    ha1z-fw-b = module.fw-ha1z_b.mgmt_public_ip
    ha2z-fw-a = module.fw-ha2z_a.mgmt_public_ip
    ha2z-fw-b = module.fw-ha2z_b.mgmt_public_ip
    ha1z-client1 = module.ha1z_client1.public_ip
    ha1z-client2 = module.ha1z_client2.public_ip
    ha2z-client1 = module.ha2z_client1.public_ip
    ha2z-client2 = module.ha2z_client2.public_ip
    vpc1-client1 = module.vpc1_client1.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 600
  records = [
    each.value
  ]
}
