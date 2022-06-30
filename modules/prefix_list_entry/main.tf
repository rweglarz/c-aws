terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


resource "aws_ec2_managed_prefix_list_entry" "this" {
  cidr           = var.cidr
  prefix_list_id = var.prefix_list_id
  description    = var.description
}
