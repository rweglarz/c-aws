variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "sharedvpc"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}
variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
    "eu-west-1a",
    "eu-west-1b",
  ]
}

variable "key_pair" {
  type    = string
  default = "rweglarz"
}

variable "cidr" {
  type    = string
  default = "172.31.1.0/24"
}

variable "ubuntu_version" {
  default = "22.04"
  type    = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "account_ids" {
  type = map
}