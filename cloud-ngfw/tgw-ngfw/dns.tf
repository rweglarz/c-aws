data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "client" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "cngfw-client"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.client.public_ip
  ]
}
resource "aws_route53_record" "attacker" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "cngfw-attacker"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.attacker.public_ip
  ]
}
resource "aws_route53_record" "victim" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "cngfw-victim"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.victim.public_ip
  ]
}

