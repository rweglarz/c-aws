variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_mgmt_prefix_list" {
  type = string
}

variable "deploy_igw" {
  type    = bool
  default = true
}

variable "subnets" {
  default = {}
}

variable "connect_tgw" {
  type    = bool
  default = false
}
variable "tgw_appliance_mode" {
  type    = bool
  default = false
}
variable "transit_gateway_id" {
  type    = string
  default = null
}
variable "transit_gateway_route_table_id" {
  type    = string
  default = null
}
