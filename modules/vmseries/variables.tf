variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "fw_version" {
  type    = string
  default = "10.2.8"
  nullable = false
}

variable "fw_instance_type" {
  default = "m5.large"
  type    = string
}

variable "key_pair" {
  type = string
}

variable "bootstrap_options" {
  type = map(string)
}

variable "interfaces" {
}

variable "ami" {
  type    = string
  default = null
}

variable "vpc_security_group_ids" {
  type    = list(any)
  default = null
}

variable "public_ip" {
  type    = bool
  default = false
}

variable "iam_instance_profile" {
  type    = string
  default = null
}
