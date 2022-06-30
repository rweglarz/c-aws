output "public_ips" {
  value = { for k, v in aws_eip.this : k => v.public_ip }
}
output "private_ip_list" {
  value = { for k, v in aws_network_interface.this : k => v.private_ip_list }
}
output "eni" {
  value = { for k, v in aws_network_interface.this : k => v.id }
}

