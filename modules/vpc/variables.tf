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

variable "transit_gateway_id" {
  type    = string
  default = null
}
