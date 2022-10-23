variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "mp"
}

variable "peer-region" {
  type    = string
  default = "eu-central-1"
}
variable "region" {
  type    = string
  default = "eu-west-3"
}
variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
    "eu-west-3a",
  ]
}

variable "key_pair" {
  default = "rweglarz"
}
variable "tgw_cidr" {
  type    = string
  default = "172.31.206.0/24"
}
variable "app5_cidr" {
  default = "172.31.205.0/24"
}

variable "ubuntu_version" {
  default = "20.04"
  type    = string
}

variable "pl-mgmt-mgmt_ips" {
  type = string
}

variable "asn" {
  default = {
    format = "4-byte"
    no     = 4200000001
  }
}
