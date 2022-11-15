data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}


resource "aws_route53_record" "ha1z_fw_a" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha1z-fw-a"
  type    = "A"
  ttl     = 600
  records = [
    one([for k,v in module.fw-ha1z_a.public_ips: v if (length(regexall("mgmt", k)) > 0)])
  ]
}

resource "aws_route53_record" "ha1z_fw_b" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha1z-fw-b"
  type    = "A"
  ttl     = 600
  records = [
    one([for k,v in module.fw-ha1z_b.public_ips: v if (length(regexall("mgmt", k)) > 0)])
  ]
}


resource "aws_route53_record" "ha2z_fw_a" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha2z-fw-a"
  type    = "A"
  ttl     = 600
  records = [
    one([for k,v in module.fw-ha2z_a.public_ips: v if (length(regexall("mgmt", k)) > 0)])
  ]
}

resource "aws_route53_record" "ha2z_fw_b" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha2z-fw-b"
  type    = "A"
  ttl     = 600
  records = [
    one([for k,v in module.fw-ha2z_b.public_ips: v if (length(regexall("mgmt", k)) > 0)])
  ]
}

resource "aws_route53_record" "ha1z_client1" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha1z-client1"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.ha1z_client1.public_ip
  ]
}

resource "aws_route53_record" "ha1z_client2" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha1z-client2"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.ha1z_client2.public_ip
  ]
}


resource "aws_route53_record" "ha2z_client1" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha2z-client1"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.ha2z_client1.public_ip
  ]
}

resource "aws_route53_record" "ha2z_client2" {
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = "ha2z-client2"
  type    = "A"
  ttl     = 600
  records = [
    aws_eip.ha2z_client2.public_ip
  ]
}

