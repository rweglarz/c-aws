
module "mfw" {
  source = "../modules/gwlb_asg_fw"

  name                 = "${var.name}-mfw"
  cidr                 = var.sec_cidr
  availability_zones   = var.availability_zones
  tgw                  = aws_ec2_transit_gateway.tgw.id
  fw_version           = var.fw_version
  fw_instance_type     = var.fw_instance_type
  iam_instance_profile = data.terraform_remote_state.mgmt.outputs.instance_profile-pan_gwlb
  key_pair             = var.key_pair
  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_prv"],
    var.bootstrap_options["gwlb"],
  )
  desired_capacity = 2
}
resource "aws_route" "sec-in-mgmt" {
  route_table_id         = data.terraform_remote_state.mgmt.outputs.aws_route_table_mgmt_id
  destination_cidr_block = var.sec_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_ec2_managed_prefix_list_entry" "sec" {
  count          = length(module.mfw.natgw-public_ips)
  cidr           = "${module.mfw.natgw-public_ips[count.index]}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-sec-natgw"
}



resource "aws_ec2_transit_gateway_vpc_attachment" "mgmt" {
  vpc_id                                          = data.terraform_remote_state.mgmt.outputs.aws_vpc_mgmt_id
  subnet_ids                                      = data.terraform_remote_state.mgmt.outputs.aws_subnet_mgmt_id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${var.name}-mgmt"
  }
}
resource "aws_ec2_transit_gateway_route_table" "mgmt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-mgmt"
  }
}
resource "aws_ec2_transit_gateway_route_table_association" "mgmt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.mgmt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "mgmt_to_sec" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.mgmt.id
  transit_gateway_route_table_id = module.mfw.aws_ec2_transit_gateway_route_table_id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "sec_to_mgmt" {
  transit_gateway_attachment_id  = module.mfw.aws_ec2_transit_gateway_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.mgmt.id
}
