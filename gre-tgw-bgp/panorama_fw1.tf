resource "panos_panorama_template_stack" "fw1" {
  name         = "aws-gre-tgw-bgp-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fw1.template_name,
    "vm common",
  ]
  description = "pat:acp"
}




module "cfg_fw1" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "aws-gre-tgw-bgp-fw1-t"

  interfaces = merge(
    {
      "ethernet1/1" = {
        static_ips         = [ format("%s/28", module.fw1.private_ip_list.private[0]) ]
        zone               = "private"
        management_profile = "ping"
        enable_dhcp = false
        create_dhcp_default_route = false
      }
    },
    {
      for k,v in aws_ec2_transit_gateway_connect_peer.fw1: format("tunnel.%d", var.envs[k].idx) => {
        static_ips         = [ format("%s/29", aws_ec2_transit_gateway_connect_peer.fw1[k].bgp_peer_address) ]
        zone               = k
        management_profile = "ping"
      }
    }
  )
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vpc_hub.subnets.private-a.cidr_block, 1)
    }
  }
  enable_ecmp = false
}


resource "panos_panorama_gre_tunnel" "fw1" {
  for_each = aws_ec2_transit_gateway_connect_peer.fw1

  template            = module.cfg_fw1.template_name
  name                = each.key
  interface           = "ethernet1/1"
  local_address_value = format("%s/28", each.value.peer_address)
  peer_address        = each.value.transit_gateway_address
  tunnel_interface    = format("tunnel.%d", var.envs[each.key].idx)

  depends_on = [ module.cfg_fw1 ]
}


resource "panos_panorama_bgp" "fw1" {
  template       = module.cfg_fw1.template_name
  virtual_router = module.cfg_fw1.vr_name
  as_format      = "4-byte"
  install_route  = true

  router_id = module.fw1.private_ip_list.private[0]
  as_number = local.asn.fw

  allow_redistribute_default_route = true

  depends_on = [ module.cfg_fw1 ]
}

resource "panos_panorama_bgp_peer_group" "fw1" {
  for_each = var.envs
  template       = module.cfg_fw1.template_name
  virtual_router = module.cfg_fw1.vr_name
  name           = each.key
  type           = "ebgp"

  depends_on = [ panos_panorama_bgp.fw1 ]
}

locals {
  fw1_bgp_peer_t = flatten([
    for env,v in aws_ec2_transit_gateway_connect_peer.fw1: [
      for p in [0, 1] : {
        interface = format("tunnel.%d", var.envs[env].idx)
        fw_ip     = format("%s/29", aws_ec2_transit_gateway_connect_peer.fw1[env].bgp_peer_address)
        tgw_ip    = tolist(v.bgp_transit_gateway_addresses)[p]
        name = "${env}-${p}"
        env  = env
      }
    ]
  ])
  fw1_bgp_peer = { for v in local.fw1_bgp_peer_t: v.name => v }
}

resource "panos_panorama_bgp_peer" "fw1" {
  for_each = local.fw1_bgp_peer

  name           = each.key
  template       = module.cfg_fw1.template_name
  virtual_router = module.cfg_fw1.vr_name

  bgp_peer_group          = panos_panorama_bgp_peer_group.fw1[each.value.env].name
  peer_as                 = local.asn.tgw
  local_address_interface = each.value.interface
  local_address_ip        = each.value.fw_ip
  peer_address_ip         = each.value.tgw_ip
  max_prefixes            = "unlimited"
  multi_hop               = 2

  keep_alive_interval = 1
  hold_time           = 6
}

resource "panos_panorama_bgp_redist_rule" "fw1" {
  template       = module.cfg_fw1.template_name
  virtual_router = module.cfg_fw1.vr_name
  route_table    = "unicast"
  name           = "0.0.0.0/0"
  set_med        = "10"
}
