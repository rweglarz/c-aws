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
variable "cidr" {
  type    = string
  default = "172.16.1.0/23"
}

variable "mgmt_ips" {
  default = {}
}

