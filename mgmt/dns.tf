resource "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}


resource "aws_route53_record" "panorama2" {
  zone_id = aws_route53_zone.w-aws.zone_id
  name    = "panorama2"
  type    = "A"
  ttl     = 3600
  records = [
    aws_eip.panorama2.public_ip
  ]
}
