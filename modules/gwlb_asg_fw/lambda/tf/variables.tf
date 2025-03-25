variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "asg-tests"
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
}

variable "sec_cidr" {
  type    = string
  default = "172.31.252.0/23"
}

variable "pl-mgmt_ips" {
  type = string
}

variable "fw_instance_type" {
  default = "m5.xlarge"
  type    = string
}

variable "dual_stack" {
  type    = bool
  default = false
}

variable "reuse_public_ips" {
  type    = bool
  default = false
}
