data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "this" {
  for_each = merge(
    {
      jumphost = module.vm_jumphost.public_ip
    },
    var.airs_tc_bootstrap!=null ? { tc = module.airs_tc[0].public_ips["mgmt"] }: {}
  )
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "${var.name}-${each.key}"
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}
