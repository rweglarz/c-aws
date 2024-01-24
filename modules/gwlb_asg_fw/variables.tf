variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "cidr" {
    type = string
}

variable "availability_zones" {
    type = list
}

variable "tgw" {
    type = string
}

variable "fw_version" {
    type = string

variable "fw_ami_id" {
    type = string
    default = null
}

variable "fw_instance_type" {
    type = string
}

variable "key_pair" {
    type = string
}

variable "bootstrap_options" {
    type = map(string)
}
variable "desired_capacity" {
    type = number
}

variable "iam_instance_profile" {
    type = string
    default = null
}

variable "target_failover" {
    default = "no_rebalance"
}
