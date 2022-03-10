variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}

variable "key_pair" {
  description = "name of the aws key pair"
  type = string
}

variable "region" {
  description = "AWS Region"
  type = string
}

variable "availability_zones" {
  description = "AZ to deploy to"
  type = list
}

variable "mgmt_cidr" {
  description = "mgmt vpc address /24 "
  type = string
}
variable "main_fw_cidr" {
  description = "main fw vpc address /24"
  type = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed in external facing security group"
  type = list(map(string))
}

variable "fw_instance_type" {
  default     = "m5.large"
  type        = string
}
variable "fw_version" {
  default     = "10.1.3"
  type        = string
}
variable "panorama_version" {
  default     = "10.1.3-h1"
  type        = string
}
variable "ubuntu_version" {
  default     = "20.04"
  type        = string
}

variable "bootstrap_options" {
  default = {}
  type    = map(string)
}
