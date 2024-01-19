resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.asn["aws"]
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [var.tgw_cidr]
  tags = {
    Name = "${var.name}-tgw"
  }
}


resource "aws_customer_gateway" "ha2z" {
  device_name = "ha2z"
  bgp_asn     = var.asn["ha2z"]
  ip_address  = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])
  type        = "ipsec.1"
}

resource "aws_vpn_connection" "ha2z" {
  transit_gateway_id    = aws_ec2_transit_gateway.tgw.id
  customer_gateway_id   = aws_customer_gateway.ha2z.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]
  tunnel1_inside_cidr   = "169.254.6.0/30"
  tunnel2_inside_cidr   = "169.254.6.4/30"
  tunnel1_preshared_key = var.psk
  tunnel2_preshared_key = var.psk
}
