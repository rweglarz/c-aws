resource "aws_networkmanager_vpc_attachment" "cwan" {
  count = (var.connect_cwan == true) ? 1 : 0

  core_network_id = var.core_network_id
  subnet_arns     = [for s in aws_subnet.this : s.arn if length(regexall("-corea", s.tags.Name)) > 0]
  vpc_arn         = aws_vpc.this.arn

  options {
    appliance_mode_support = var.appliance_mode
  }
  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}
