resource "panos_panorama_template_stack" "aws_ha1z_a" {
  name         = "aws-ha1z-a"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha1z.name,
    "vm-ha",
    "vm common",
  ]
}
resource "panos_panorama_template_stack" "aws_ha1z_b" {
  name         = "aws-ha1z-b"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha1z.name,
    "vm-ha",
    "vm common",
  ]
}

resource "panos_panorama_template_variable" "aws_ha1z_a-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.aws_ha1z_a.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = module.fw-ha1z_b.private_ip_list["mgmt"][0]
}
resource "panos_panorama_template_variable" "aws_ha1z_a-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.aws_ha1z_a.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = module.fw-ha1z_a.private_ip_list["ha2"][0]
}
resource "panos_panorama_template_variable" "aws_ha1z_a-ha2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha1z_a.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha1z_a["ha2"].cidr_block, 1)
}

resource "panos_panorama_template_variable" "aws_ha1z_b-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.aws_ha1z_b.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = module.fw-ha1z_a.private_ip_list["mgmt"][0]
}
resource "panos_panorama_template_variable" "aws_ha1z_b-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.aws_ha1z_b.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = module.fw-ha1z_b.private_ip_list["ha2"][0]
}
resource "panos_panorama_template_variable" "aws_ha1z_b-ha2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha1z_b.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha1z_a["ha2"].cidr_block, 1)
}





resource "panos_panorama_template" "ha1z" {
  name = "aws-ha1z"
}
resource "panos_panorama_ethernet_interface" "ha1z_eth1_2" {
  template                  = panos_panorama_template.ha1z.name
  name                      = "ethernet1/2"
  vsys                      = "vsys1"
  mode                      = "layer3"
  static_ips                = ["${module.fw-ha1z_a.private_ip_list["internet"][1]}/28"]
  enable_dhcp               = false
  create_dhcp_default_route = false
}
resource "panos_panorama_ethernet_interface" "ha1z_eth1_3" {
  template    = panos_panorama_template.ha1z.name
  name        = "ethernet1/3"
  vsys        = "vsys1"
  mode        = "layer3"
  static_ips  = ["${module.fw-ha1z_a.private_ip_list["prv"][1]}/28"]
  enable_dhcp = false
}
resource "panos_panorama_tunnel_interface" "ha1z_tun11" {
  template           = panos_panorama_template.ha1z.name
  name               = "tunnel.11"
  vsys               = "vsys1"
  static_ips         = ["169.254.12.1/30"]
  management_profile = "ping"
}


resource "panos_zone" "ha1z_internet" {
  template = panos_panorama_template.ha1z.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha1z_eth1_2.name,
  ]
}
resource "panos_zone" "ha1z_private" {
  template = panos_panorama_template.ha1z.name
  name     = "private"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.ha1z_eth1_3.name,
    panos_panorama_tunnel_interface.ha1z_tun11.name,
  ]
}



resource "panos_virtual_router" "ha1z_vr1" {
  name     = "vr1"
  template = panos_panorama_template.ha1z.name
  interfaces = [
    panos_panorama_ethernet_interface.ha1z_eth1_2.name,
    panos_panorama_ethernet_interface.ha1z_eth1_3.name,
    panos_panorama_tunnel_interface.ha1z_tun11.name,
  ]
}
resource "panos_panorama_static_route_ipv4" "ha1z_vr1_dg" {
  template       = panos_panorama_template.ha1z.name
  virtual_router = panos_virtual_router.ha1z_vr1.name
  name           = "internet"
  destination    = "0.0.0.0/0"
  next_hop       = cidrhost(aws_subnet.ha1z_a["internet"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.ha1z_eth1_2.name
}
resource "panos_panorama_static_route_ipv4" "ha1z_vr1_private" {
  template       = panos_panorama_template.ha1z.name
  virtual_router = panos_virtual_router.ha1z_vr1.name
  name           = "private"
  destination    = "172.16.0.0/12"
  next_hop       = cidrhost(aws_subnet.ha1z_a["prv"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.ha1z_eth1_3.name
}
resource "panos_panorama_static_route_ipv4" "ha1z_vr1_vpn" {
  template       = panos_panorama_template.ha1z.name
  virtual_router = panos_virtual_router.ha1z_vr1.name
  type           = ""
  name           = "tunnel"
  destination    = "172.31.2.0/24"
  interface      = panos_panorama_tunnel_interface.ha1z_tun11.name
}
resource "panos_panorama_ike_gateway" "ha1z_ha2z" {
  template      = panos_panorama_template.ha1z.name
  name          = "ha2z"
  peer_ip_type  = "ip"
  peer_ip_value = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])

  interface           = "ethernet1/2"
  pre_shared_key      = "secret"
  ikev1_exchange_mode = "main"

  local_id_type  = "ipaddr"
  local_id_value = one([for k, v in module.fw-ha1z_a.public_ips : v if length(regexall("internet", k)) > 0])
  peer_id_type   = "ipaddr"
  peer_id_value  = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}
resource "panos_panorama_ipsec_tunnel" "ha1z_ha2z" {
  name             = "ha2z"
  template         = panos_panorama_template.ha1z.name
  tunnel_interface = panos_panorama_tunnel_interface.ha1z_tun11.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.ha1z_ha2z.name

  enable_tunnel_monitor         = true
  tunnel_monitor_profile        = panos_panorama_monitor_profile.ha1z_fo.name
  tunnel_monitor_destination_ip = "169.254.12.2"
}

resource "panos_panorama_monitor_profile" "ha1z_fo" {
  template  = panos_panorama_template.ha1z.name
  name      = "fo-2-5"
  interval  = 2
  threshold = 5
  action    = "fail-over"
}
resource "panos_panorama_management_profile" "ha1z_ping" {
  template = panos_panorama_template.ha1z.name
  name     = "ping"
  ping     = true
}



resource "panos_security_rule_group" "ha1z_ipsec" {
  position_keyword = "bottom"
  device_group     = "aws-ha1z"
  rule {
    name                  = "ipsec allow"
    audit_comment         = ""
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications = [
      "ipsec",
    ]
    services   = ["application-default"]
    categories = ["any"]
    action     = "allow"
  }
}
