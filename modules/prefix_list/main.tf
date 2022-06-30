terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


resource "aws_ec2_managed_prefix_list" "this" {
  name           = var.name
  address_family = "IPv4"
  max_entries    = 15

  dynamic "entry" {
    for_each = var.ips
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

output "id" {
  value = aws_ec2_managed_prefix_list.this.id
}
