resource "aws_instance" "this" {
  ami           = coalesce(var.ami, data.aws_ami.ubuntu.id)
  instance_type = "t2.micro"
  user_data     = var.user_data
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.vpc_security_group_ids

  lifecycle { ignore_changes = [ ami ] }
  tags = {
    Name = var.name
  }
}

resource "aws_eip" "this" {
  count = var.associate_public_ip ? 1 : 0
  instance = aws_instance.this.id
}
