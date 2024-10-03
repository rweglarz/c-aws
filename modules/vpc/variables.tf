variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "extra_cidr_blocks" {
  type = list
  default = []
}

variable "enable_dns_hostnames" {
  type = bool
  default = false
}

variable "public_mgmt_prefix_list" {
  type = string
}

variable "subnet_mask_length" {
  type = number
  default = 28
}

variable "deploy_igw" {
  type    = bool
  default = true
}
variable "deploy_natgw" {
  type    = bool
  default = false
  description = "requires subnets with name natgw to exist"
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

variable gwlb_service_name {
  type    = string
  default = null
}

variable routing_scenario {
  type = number
  default = null
}

variable tags {
  default = null
}
