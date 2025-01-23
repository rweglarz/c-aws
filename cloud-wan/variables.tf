variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "cwan"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "key_pair" {
  type    = string
  default = "rweglarz"
}

variable "cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "pl-mgmt-mgmt_ips" {
  default = {
    eu-west-1    = "pl-02d9932acdc462a47"
    eu-central-1 = "pl-0139bb989ef6d1988"
    us-east-1    = "pl-063addd981c50458e"
  }
}

variable "bootstrap_options" {
  type = map(string)
  default = {
    panorama-server             = "192.0.2.10"
    authcodes                   = "D0000000"
    cgname                      = "cg2"
    plugin-op-commands          = "set-cores:2"
    dhcp-accept-server-hostname = "yes"
  }
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "dns_zone" {
  type = string
}

variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
}
