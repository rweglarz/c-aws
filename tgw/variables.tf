variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "m"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c",
  ]
}

variable "key_pair" {
  type    = string
  default = "rweglarz"
}

variable "sec_cidr" {
  type    = string
  default = "172.31.252.0/23"
}
variable "tgw_cidr" {
  type    = string
  default = "172.31.254.0/24"
}
variable "ingress_cidr" {
  type    = string
  default = "172.31.250.0/23"
}
variable "app0_cidr" {
  type    = string
  default = "172.31.200.0/24"
}
variable "app1_cidr" {
  type    = string
  default = "172.31.201.0/24"
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}
variable "pl-mgmt-mgmt_ips" {
  type = string
}

variable "bootstrap_options" {
  type = map(map(string))
}

variable "ubuntu_version" {
  default = "20.04"
  type    = string
}

variable "fw_instance_type" {
  default = "m5.large"
  type    = string
}
variable "fw_version" {
  default = "10.1.9"
  type    = string
}

variable "asn" {
  default = {
    format = "4-byte"
    no     = 4200000000
  }
}

variable "dns_zone" {
  type = string
}

variable "target_failover" {
  default = "no_rebalance"
}
