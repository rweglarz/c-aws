data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = {
    masg-mgmt = module.l-mgmt.public_ip
    masg-env1 = module.l-env1_s1.public_ip
    masg-env2 = module.l-env2_s1.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 180
  records = [
    each.value
  ]
}
