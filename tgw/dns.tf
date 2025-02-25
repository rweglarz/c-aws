data "aws_route53_zone" "w-aws" {
  name = var.dns_zone
}
