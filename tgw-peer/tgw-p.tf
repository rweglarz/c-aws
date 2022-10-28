resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.asn["no"]
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [var.tgw_cidr]
  tags = {
    Name = "${var.name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${var.name}-spokes"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment" "main-tgw" {
  peer_region             = var.peer-region
  peer_transit_gateway_id = data.terraform_remote_state.tgw.outputs.transit_gateway_id
  transit_gateway_id      = aws_ec2_transit_gateway.tgw.id

  tags = {
    Name = "tgw-${var.peer-region}"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "main-tgw" {
  provider                      = aws.peer
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
}

resource "aws_ec2_transit_gateway_route" "local-to-peer-app0" {
  destination_cidr_block         = "172.31.200.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.main-tgw
  ]
}
resource "aws_ec2_transit_gateway_route" "local-to-peer-app1" {
  destination_cidr_block         = "172.31.201.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.main-tgw
  ]
}

resource "aws_ec2_transit_gateway_route" "peer-to-local-app5" {
  provider                       = aws.peer
  destination_cidr_block         = "172.31.205.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw.outputs.transit_gateway_route_tables["sec"]
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.main-tgw
  ]
}
resource "aws_ec2_transit_gateway_route_table_association" "peer-sec" {
  provider                       = aws.peer
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw.outputs.transit_gateway_route_tables["spoke"]
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.main-tgw
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "peer" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.main-tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.main-tgw
  ]
}
resource "aws_ec2_transit_gateway_route_table_propagation" "app5_to_spoke" {
  transit_gateway_attachment_id  = module.vpc-app5.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}
