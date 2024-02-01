output "public_ip" {
    value = var.associate_public_ip ? aws_eip.this[0].address : null 
}
