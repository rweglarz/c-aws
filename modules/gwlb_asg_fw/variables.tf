variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "availability_zones" {
  type = list
}

variable "fw_version" {
  type = string
  default = "11.1.4-h13"
}

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

variable "deregistration_delay" {
  default = 0
}

variable "health_check_port" {
  default = 54321
}

variable "vpc_id" {
}

variable "interfaces" {
}

variable "gwlb_subnet_ids" {
}

variable "dual_stack" {
  default = false
}
