variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "user_data" {
  type    = string
  default = null
}

variable "key_name" {
  type    = string
  default = null
}

variable "ubuntu_version" {
  default = "22.04"
  type    = string
}

variable "ami" {
  type = string
  default = null
}

variable "associate_public_ip" {
  type    = bool
  default = true
}

variable "vpc_security_group_ids" {
  type = list
  default = null
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "iam_instance_profile" {
  type = string
  default = null
}
