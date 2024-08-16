variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "gre-tgw"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
    "eu-west-1a",
    "eu-west-1b",
  ]
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
  type = string
  default = "pl-02d9932acdc462a47"
}
variable "pl-mgmt-csp_nat_ips" {
  type = string
  default = "pl-029b5d80e69d9bc9e"
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

variable "envs" {
  default = {
    c1 = {
      vpcs = {
        a = {}
        b = {}
      }
      idx = 1
    }
    c2 = {
      vpcs = {
        a = {}
        b = {}
      }
      idx = 2
    }
    c3 = {
      vpcs = {
        a = {}
        b = {}
      }
      idx = 3
    }
  }
}

variable "block-fw" {
  default = {
    fw1 = false
    fw2 = false
  }
}
