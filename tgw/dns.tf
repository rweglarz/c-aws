data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}

resource "aws_route53_record" "app0" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "app0"
  type    = "A"
  ttl     = 600
  records = [
    aws_instance.app0_app0.public_ip
  ]
}

resource "aws_route53_record" "app1a" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "app1a"
  type    = "A"
  ttl     = 600
  records = [
    aws_instance.app1a_app1.public_ip
  ]
}
resource "aws_route53_record" "app1b" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "app1b"
  type    = "A"
  ttl     = 600
  records = [
    aws_instance.app1b_app1.public_ip
  ]
}

