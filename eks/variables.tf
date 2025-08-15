variable "name" {
  default = "eks"
  type    = string
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
  ]
}

variable "key_pair" {
  type    = string
  default = "rweglarz"
}

variable "cidr" {
  type    = string
  default = "172.30.0.0/20"
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "pl-mgmt-csp_nat_ips" {}

variable "dns_zone" {
  type = string
}

variable "k8s_version" {
  default = "1.31"
}

variable "key_name" {
  default = "rweglarz"
}

variable "panorama_ip" { }

variable "gwlb_service_name" {
  default = null
}
