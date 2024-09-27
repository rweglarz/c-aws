output "id" {
  value = aws_instance.this.id
}

output "public_ip" {
    value = var.associate_public_ip ? aws_eip.this[0].public_ip : null 
}

output "private_ip" {
    value = aws_instance.this.private_ip
}
