variable "region" {
  type    = string
  default = "eu-west-1"
}
variable "availability_zones" {
  default = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]
}
variable "name" {
  type = string
}
variable "account_id" {
  type = string
}
variable "cidr" {
  type    = string
  default = "172.16.0.0/22"
}
variable "log_group" {
  type  = string
  default  = "PaloAltoCloudNGFW"
}
variable "log_retention_days" {
  type = number
  default = 30
}

variable "mgmt_ips" {
  default = {}
}

variable "dns_zone" {
  type = string
}

variable "iam_instance_profile" {
  type = string
  default = null
}

variable "pl-mgmt-mgmt_ips" {
  default = {
    eu-west-1    = "pl-02d9932acdc462a47"
    eu-central-1 = "pl-0139bb989ef6d1988"
    us-east-1    = "pl-063addd981c50458e"
  }
}

variable "user_arn" {
  type = string
}
