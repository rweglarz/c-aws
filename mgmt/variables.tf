variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "key_pair" {
  description = "name of the aws key pair"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
}

variable "mgmt_cidr" {
  description = "mgmt vpc address /24 "
  type        = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}
variable "tmp_ips" {
  description = "List of tmp IPs allowed external access"
  type        = list(map(string))
  default     = []
}


variable "panorama_version" {
  default = "10.1.3-h1"
  type    = string
}
variable "ubuntu_version" {
  default = "20.04"
  type    = string
}
variable "bootstrap_options" {
  type = map(map(string))
}

variable "dns_zone" {
  type = string
}

variable "cloud_ngfw_principals" {
  type = list
}
