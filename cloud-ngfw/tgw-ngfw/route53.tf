resource "aws_route53_resolver_endpoint" "this" {
  name      = "${var.name}-sec"
  direction = "INBOUND"

  security_group_ids = [
    module.vpc-sec.sg_private_id
  ]

  ip_address {
    subnet_id = module.vpc-sec.subnets.route53-a.id
  }

  ip_address {
    subnet_id = module.vpc-sec.subnets.route53-b.id
  }
}
