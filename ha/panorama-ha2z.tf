resource "panos_panorama_template_stack" "aws_ha2z_a" {
  name         = "aws-ha2z-a"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha2z.name,
    "vm-ha",
    "vm common",
  ]
}
resource "panos_panorama_template_stack" "aws_ha2z_b" {
  name         = "aws-ha2z-b"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha2z.name,
    "vm-ha",
    "vm common",
  ]
}

resource "panos_panorama_template_variable" "aws_ha2z_a-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = module.fw-ha2z_b.private_ip_list["mgmt"][0]
}
resource "panos_panorama_template_variable" "aws_ha2z_a-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = module.fw-ha2z_a.private_ip_list["ha2"][0]
}
resource "panos_panorama_template_variable" "aws_ha2z_a-ha2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_a["ha2"].cidr_block, 1)
}

resource "panos_panorama_template_variable" "aws_ha2z_b-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = module.fw-ha2z_a.private_ip_list["mgmt"][0]
}
resource "panos_panorama_template_variable" "aws_ha2z_b-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = module.fw-ha2z_b.private_ip_list["ha2"][0]
}
resource "panos_panorama_template_variable" "aws_ha2z_b-ha2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_b["ha2"].cidr_block, 1)
}
resource "panos_panorama_template_variable" "aws_ha2z_a-eth1_3_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$eth1_3-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_a["prv"].cidr_block, 1)
}
resource "panos_panorama_template_variable" "aws_ha2z_b-eth1_3_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$eth1_3-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_b["prv"].cidr_block, 1)
}












resource "panos_panorama_template" "ha2z" {
  name = "aws-ha2z"
}
resource "panos_panorama_ethernet_interface" "ha2z_eth1_2" {
  template = panos_panorama_template.ha2z.name
  name     = "ethernet1/2"
  vsys     = "vsys1"
  mode     = "layer3"
  #static_ips = [local.ip_mask["internet"][1]]
  #static_ips = ["${module.fw-ha2z_a.aws_network_interface.this["internet"].private_ip_list[0]}/28"]
  enable_dhcp               = true
  create_dhcp_default_route = true
  management_profile = "ping"
}
resource "panos_panorama_ethernet_interface" "ha2z_eth1_3" {
  template = panos_panorama_template.ha2z.name
  name     = "ethernet1/3"
  vsys     = "vsys1"
  mode     = "layer3"
  #static_ips = ["${module.fw-ha2z_a.aws_network_interface.this["prv"].private_ip_list[0]}/28"]
  enable_dhcp = true
  create_dhcp_default_route = false
  management_profile = "ping"
}
resource "panos_panorama_tunnel_interface" "ha2z_tun11" {
  template           = panos_panorama_template.ha2z.name
  name               = "tunnel.11"
  vsys               = "vsys1"
  static_ips         = ["169.254.12.2/30"]
  management_profile = "ping"
}
resource "panos_panorama_template_variable" "aws_ha2z-eth1_3_gw" {
  template = panos_panorama_template.ha2z.name
  name     = "$eth1_3-gw"
  type     = "ip-netmask"
  value    = "192.168.1.1"
}


resource "panos_zone" "ha2z_internet" {
  template = panos_panorama_template.ha2z.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha2z_eth1_2.name,
  ]
}
resource "panos_zone" "ha2z_private" {
  template = panos_panorama_template.ha2z.name
  name     = "private"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha2z_eth1_3.name,
    panos_panorama_tunnel_interface.ha2z_tun11.name,
  ]
}

resource "panos_panorama_management_profile" "ha2z_ping" {
  template = panos_panorama_template.ha2z.name
  name     = "ping"
  ping     = true
}




resource "panos_virtual_router" "ha2z_vr1" {
  name     = "vr1"
  template = panos_panorama_template.ha2z.name
  interfaces = [
    panos_panorama_ethernet_interface.ha2z_eth1_2.name,
    panos_panorama_ethernet_interface.ha2z_eth1_3.name,
    panos_panorama_tunnel_interface.ha2z_tun11.name,
  ]
}
resource "panos_panorama_static_route_ipv4" "ha2z_vr1_private" {
  template       = panos_panorama_template.ha2z.name
  virtual_router = panos_virtual_router.ha2z_vr1.name
  name           = "private"
  destination    = "172.16.0.0/12"
  next_hop       = panos_panorama_template_variable.aws_ha2z_b-eth1_3_gw.name
  interface      = panos_panorama_ethernet_interface.ha2z_eth1_3.name
  depends_on = [
    panos_panorama_template_variable.aws_ha2z-eth1_3_gw
  ]
}
resource "panos_panorama_static_route_ipv4" "ha2z_vr1_vpn" {
  template       = panos_panorama_template.ha2z.name
  virtual_router = panos_virtual_router.ha2z_vr1.name
  type           = ""
  name           = "tunnel"
  destination    = "172.31.1.0/24"
  interface      = panos_panorama_tunnel_interface.ha2z_tun11.name
}
resource "panos_panorama_ike_gateway" "ha2z_ha1z" {
  template            = panos_panorama_template.ha2z.name
  name                = "ha1z"
  peer_ip_type        = "ip"
  peer_ip_value       = one([for k, v in module.fw-ha1z_a.public_ips : v if length(regexall("internet", k)) > 0])
  interface           = "ethernet1/2"
  pre_shared_key      = "secret"
  ikev1_exchange_mode = "main"

  local_id_type  = "ipaddr"
  local_id_value = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])
  peer_id_type   = "ipaddr"
  peer_id_value  = one([for k, v in module.fw-ha1z_a.public_ips : v if length(regexall("internet", k)) > 0])

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}
resource "panos_panorama_ipsec_tunnel" "ha2z_ha1z" {
  name             = "ha1z"
  template         = panos_panorama_template.ha2z.name
  tunnel_interface = panos_panorama_tunnel_interface.ha2z_tun11.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.ha2z_ha1z.name
}


resource "panos_security_rule_group" "ha2z_ipsec" {
  position_keyword = "bottom"
  device_group     = "aws-ha2z"
  rule {
    name                  = "ipsec ping allow"
    audit_comment         = ""
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications = [
      "ipsec",
      "ping",
    ]
    services   = ["application-default"]
    categories = ["any"]
    action     = "allow"
  }
}
