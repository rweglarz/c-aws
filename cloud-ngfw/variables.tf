variable "region" {
  type    = string
  default = "us-east-1"
}
variable "zones" {
  default = [
    "us-east-1a",
    "us-east-1b",
  ]
}
variable "name" {
  type = string
}
variable "account_id" {
  type = string
}
variable "rule_stack" {
  type = string
}
variable "link_id" {
  type   = string
  default = null
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

variable "cert_path" {
  type = string
}

variable "iam_instance_profile" {
  type = string
  default = null
}
