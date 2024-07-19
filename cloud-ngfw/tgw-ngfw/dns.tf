data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = {
    cngfw-client1  = module.client1.public_ip
    cngfw-attacker = aws_eip.attacker.public_ip
    cngfw-victim   = aws_eip.victim.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}
