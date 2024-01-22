variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "ha"
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

variable "ha1z_cidr" {
  type    = string
  default = "172.31.1.0/24"
}
variable "ha2z_cidr" {
  type    = string
  default = "172.31.2.0/24"
}

variable "tgw_cidr" {
  type    = string
  default = "172.31.16.0/24"
}

variable "vpc1_cidr" {
  type    = string
  default = "172.31.17.0/24"
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
  type = map(map(string))
}

variable "ubuntu_version" {
  default = "20.04"
  type    = string
}

variable "fw_instance_type" {
  default = "m5.xlarge"
  type    = string
}
variable "fw_version" {
  default = "10.1.9"
  type    = string
}

variable "subnets" {
  type = map(map(any))
  default = {
    mgmt     = { index = 0 },
    ha2      = { index = 1 },
    internet = { index = 2 },
    prv      = { index = 3 },
    client1  = { index = 4 },
    client2  = { index = 5 },
  }
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "dns_zone" {
  type = string
}

variable "asn" {
  default = {
    aws  = "64512"
    ha1z = "64521"
    ha2z = "64522"
  }
}

variable "psk" {
  type = string
}