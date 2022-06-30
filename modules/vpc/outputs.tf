output "vpc" {
  value = aws_vpc.this
}


output "sg_public_id" {
  value = aws_security_group.public.id
}
output "sg_open_id" {
  value = aws_security_group.open.id
}
output "sg_private_id" {
  value = aws_security_group.private.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this[0].id
}
