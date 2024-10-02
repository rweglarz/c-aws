variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "modasg"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
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

variable "env_cidr" {
  type    = string
  default = "172.31.192.0/18"
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

variable "pl-mgmt-mgmt_ips" {
  type = string
}

variable "bootstrap_options" {
  type = map(string)
}

variable "mgmt_ips" {
}

variable "ubuntu_version" {
  default = "22.04"
  type    = string
}

variable "fw_instance_type" {
  default = "m5.large"
  type    = string
}

variable "fw_instance_profile" {
  type = string
}

variable "fw_version" {
  default = "11.2.0"
  type    = string
}

variable "fw_ami_id" {
  default = null
}

variable "dns_zone" {
  type = string
}

variable "fw_license_type" {
  default = "byol"
}

variable "vmseries_product_code" {
  default = "6njl1pau431dv1qxipg63mvah"
}
