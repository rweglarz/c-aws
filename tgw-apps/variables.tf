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
  ]
}

variable "key_pair" {
  default = "rweglarz"
}

variable "app0_cidr" {
  default = "172.31.200.0/24"
}
variable "app1_cidr" {
  default = "172.31.201.0/24"
}
variable "app2_cidr" {
  default = "172.31.202.0/24"
}
variable "app3_cidr" {
  default = "172.31.203.0/24"
}
variable "app4_cidr" {
  default = "172.31.204.0/24"
}

variable "ubuntu_version" {
  default = "20.04"
  type    = string
}

variable "pl-mgmt-mgmt_ips" {
  type = string
}
variable "container_image" {
  type = string
}
