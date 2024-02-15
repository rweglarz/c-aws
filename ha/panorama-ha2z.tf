locals {
  aws_tunnel_ips = [
    {
       pan_tunnel_int = aws_vpn_connection.ha2z.tunnel1_cgw_inside_address
       aws_tunnel_int = aws_vpn_connection.ha2z.tunnel1_vgw_inside_address
       aws_public     = aws_vpn_connection.ha2z.tunnel1_address
    },
    {
       pan_tunnel_int = aws_vpn_connection.ha2z.tunnel2_cgw_inside_address
       aws_tunnel_int = aws_vpn_connection.ha2z.tunnel2_vgw_inside_address
       aws_public     = aws_vpn_connection.ha2z.tunnel2_address
    }
  ]
}
resource "panos_device_group" "aws_ha2z" {
  name = "aws-ha2z"

  lifecycle {
    create_before_destroy = true
  }
}
resource "panos_device_group_parent" "aws_ha2z" {
  device_group = panos_device_group.aws_ha2z.name
  parent       = "aws vm common"

  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_template_stack" "aws_ha2z_a" {
  name         = "aws-ha2z-a"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha2z.name,
    "vm-ha-ha2-eth1-1",
    "vm common",
  ]
  description = "pat:acp"
}
resource "panos_panorama_template_stack" "aws_ha2z_b" {
  name         = "aws-ha2z-b"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.ha2z.name,
    "vm-ha-ha2-eth1-1",
    "vm common",
  ]
  description = "pat:acp"
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
resource "panos_panorama_template_variable" "aws_ha2z_a-eth1_2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$eth1_2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_a["internet"].cidr_block, 1)
}
resource "panos_panorama_template_variable" "aws_ha2z_b-eth1_2_gw" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$eth1_2-gw"
  type           = "ip-netmask"
  value          = cidrhost(aws_subnet.ha2z_b["internet"].cidr_block, 1)
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

  #static_ips = ["$eth1_2-ip"]
  enable_dhcp               = true
  create_dhcp_default_route = true
  management_profile = "ping"
}
resource "panos_panorama_template_variable" "aws_ha2z_a-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$eth1_2-ip"
  type           = "ip-netmask"
  value          = "${module.fw-ha2z_a.private_ip_list["internet"][0]}/28"
}
resource "panos_panorama_template_variable" "aws_ha2z_b-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$eth1_2-ip"
  type           = "ip-netmask"
  value          = "${module.fw-ha2z_b.private_ip_list["internet"][0]}/28"
}
resource "panos_panorama_ethernet_interface" "ha2z_eth1_3" {
  template = panos_panorama_template.ha2z.name
  name     = "ethernet1/3"
  vsys     = "vsys1"
  mode     = "layer3"

  #static_ips = ["$eth1_3-ip"]
  enable_dhcp               = true
  create_dhcp_default_route = false
  management_profile = "ping"
}
resource "panos_panorama_template_variable" "aws_ha2z_a-eth1_3_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_a.name
  name           = "$eth1_3-ip"
  type           = "ip-netmask"
  value          = "${module.fw-ha2z_a.private_ip_list["prv"][0]}/28"
}
resource "panos_panorama_template_variable" "aws_ha2z_b-eth1_3_ip" {
  template_stack = panos_panorama_template_stack.aws_ha2z_b.name
  name           = "$eth1_3-ip"
  type           = "ip-netmask"
  value          = "${module.fw-ha2z_b.private_ip_list["prv"][0]}/28"
}
resource "panos_panorama_tunnel_interface" "ha2z_tun11" {
  template           = panos_panorama_template.ha2z.name
  name               = "tunnel.11"
  vsys               = "vsys1"
  static_ips         = ["169.254.12.2/30"]
  management_profile = "ping"
}
resource "panos_panorama_tunnel_interface" "ha2z_aws" {
  count = 2
  template           = panos_panorama_template.ha2z.name
  name               = "tunnel.${31+count.index}"
  vsys               = "vsys1"
  static_ips         = ["${local.aws_tunnel_ips[count.index].pan_tunnel_int}/30"]
  management_profile = "ping"
}
resource "panos_panorama_template_variable" "aws_ha2z-eth1_2_ip" {
  template = panos_panorama_template.ha2z.name
  name     = "$eth1_2-ip"
  type     = "ip-netmask"
  value    = "192.168.2.2"
}
resource "panos_panorama_template_variable" "aws_ha2z-eth1_3_ip" {
  template = panos_panorama_template.ha2z.name
  name     = "$eth1_3-ip"
  type     = "ip-netmask"
  value    = "192.168.3.2"
}
resource "panos_panorama_template_variable" "aws_ha2z-eth1_2_gw" {
  template = panos_panorama_template.ha2z.name
  name     = "$eth1_2-gw"
  type     = "ip-netmask"
  value    = "192.168.2.1"
}
resource "panos_panorama_template_variable" "aws_ha2z-eth1_3_gw" {
  template = panos_panorama_template.ha2z.name
  name     = "$eth1_3-gw"
  type     = "ip-netmask"
  value    = "192.168.3.1"
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
    panos_panorama_tunnel_interface.ha2z_aws[0].name,
    panos_panorama_tunnel_interface.ha2z_aws[1].name,
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
    panos_panorama_tunnel_interface.ha2z_aws[0].name,
    panos_panorama_tunnel_interface.ha2z_aws[1].name,
  ]
}

# resource "panos_panorama_static_route_ipv4" "ha2z_vr1_dg" {
#   template       = panos_panorama_template.ha2z.name
#   virtual_router = panos_virtual_router.ha2z_vr1.name
#   name           = "internet"
#   destination    = "0.0.0.0/0"
#   next_hop       = panos_panorama_template_variable.aws_ha2z-eth1_2_gw.name
#   interface      = panos_panorama_ethernet_interface.ha2z_eth1_2.name
# }

resource "panos_panorama_static_route_ipv4" "ha2z_vr1_private_a" {
  template       = panos_panorama_template.ha2z.name
  virtual_router = panos_virtual_router.ha2z_vr1.name
  name           = "private-a"
  destination    = "172.16.0.0/12"
  next_hop       = cidrhost(aws_subnet.ha2z_a["prv"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.ha2z_eth1_3.name
  metric         = 11
}
resource "panos_panorama_static_route_ipv4" "ha2z_vr1_private_b" {
  template       = panos_panorama_template.ha2z.name
  virtual_router = panos_virtual_router.ha2z_vr1.name
  name           = "private-b"
  destination    = "172.16.0.0/12"
  next_hop       = cidrhost(aws_subnet.ha2z_b["prv"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.ha2z_eth1_3.name
  metric         = 12
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


resource "panos_panorama_ike_gateway" "ha2z_aws" {
  count = 2
  template            = panos_panorama_template.ha2z.name
  name                = "aws${count.index+1}"
  peer_ip_type        = "ip"
  peer_ip_value       = local.aws_tunnel_ips[count.index].aws_public
  interface           = "ethernet1/2"
  pre_shared_key      = var.psk
  ikev1_exchange_mode = "main"
  version             = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])
  peer_id_type   = "ipaddr"
  peer_id_value  = local.aws_tunnel_ips[count.index].aws_public

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
  enable_liveness_check        = true
  liveness_check_interval      = 2
}
resource "panos_panorama_ipsec_tunnel" "ha2z_aws" {
  count = 2
  name             = "aws${count.index+1}"
  template         = panos_panorama_template.ha2z.name
  tunnel_interface = panos_panorama_tunnel_interface.ha2z_aws[count.index].name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.ha2z_aws[count.index].name
}



resource "panos_panorama_bgp" "ha2z" {
  template         = panos_panorama_template.ha2z.name
  virtual_router   = panos_virtual_router.ha2z_vr1.name
  install_route    = true

  router_id = "169.254.21.2"
  as_number = var.asn["ha2z"]
}
resource "panos_panorama_bgp_peer_group" "ha2z-aws" {
  template       = panos_panorama_template.ha2z.name
  virtual_router = panos_virtual_router.ha2z_vr1.name
  name           = "aws"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.ha2z
  ]
}
resource "panos_panorama_bgp_peer" "ha2z-aws" {
  count = 2
  template                = panos_panorama_template.ha2z.name
  name                    = "aws${count.index+1}"
  virtual_router          = panos_virtual_router.ha2z_vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.ha2z-aws.name
  peer_as                 = var.asn["aws"]
  local_address_interface = panos_panorama_tunnel_interface.ha2z_aws[count.index].name
  local_address_ip        = panos_panorama_tunnel_interface.ha2z_aws[count.index].static_ips[0]
  peer_address_ip         = local.aws_tunnel_ips[count.index].aws_tunnel_int
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_redist_rule" "ha2z" {
  for_each = {
    local  = var.ha2z_cidr
    dummy1 = "192.168.21.0/24"
    dummy2 = "192.168.22.0/24"
    dummy3 = "192.168.23.0/24"
  }
  template        = panos_panorama_template.ha2z.name
  virtual_router  = panos_virtual_router.ha2z_vr1.name
  route_table     = "unicast"
  name            = each.value

  depends_on = [
    panos_panorama_bgp.ha2z
  ]
  lifecycle { create_before_destroy = true }
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

resource "panos_panorama_nat_rule_group" "aws_ha2z-pre-nat" {
  device_group = panos_device_group.aws_ha2z.name
  rule {
    name = "default outbound snat"
    original_packet {
      source_zones          = [panos_zone.ha2z_private.name]
      destination_zone      = panos_zone.ha2z_internet.name
      source_addresses      = ["172.16.0.0/12"]
      destination_addresses = ["any"]

    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = panos_panorama_ethernet_interface.ha2z_eth1_2.name
          }
        }
      }
      destination {
      }
    }
  }
}

locals {
  ha2_route_monitor_base = "set template ${panos_panorama_template.ha2z.name} config network virtual-router ${panos_virtual_router.ha2z_vr1.name} routing-table ip static-route private-a path-monitor"
}
output "panorama_h2_route_monitor" {
  value = [
    "${local.ha2_route_monitor_base} monitor-destinations r-a enable yes",
    "${local.ha2_route_monitor_base} monitor-destinations r-a source DHCP",
    "${local.ha2_route_monitor_base} monitor-destinations r-a destination ${cidrhost(aws_subnet.ha2z_a["prv"].cidr_block, 1)}",
    "${local.ha2_route_monitor_base} monitor-destinations r-a interval 1",
    "${local.ha2_route_monitor_base} monitor-destinations r-a count 3",
    "${local.ha2_route_monitor_base} enable yes",
    "${local.ha2_route_monitor_base} failure-condition any",
    "${local.ha2_route_monitor_base} hold-time 0",
  ]
}
