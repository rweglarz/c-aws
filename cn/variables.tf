variable "name" {
  default = "cn"
  type    = string
}

variable "kubeconfig_output_path" {
  default = "~/.kube/config-eks"
  type    = string
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "availability_zones" {
  description = "AZ to deploy to"
  type        = list(any)
  default = [
    "eu-west-3a",
    "eu-west-3b",
  ]
}

variable "key_pair" {
  type    = string
  default = "rweglarz"
}

variable "cidr" {
  type    = string
  default = "172.31.0.0/22"
}

variable "subnets" {
  type = map(map(any))
  default = {
    pub = { index = 0 },
    prv = { index = 1 },
  }
}


variable "mgmt_ips" {
  description = "List of IPs allowed for external access"
  type        = list(map(string))
}

variable "pl-mgmt-csp_nat_ips" {}

variable "dns_zone" {
  type = string
}

variable "k8s_version" {
  default = "1.24"
}

variable "key_name" {
  default = "rweglarz"
}

variable "ubuntu_version" {
  default = "20.04"
  type    = string
}

variable "panorama1_ip" { }
variable "panorama2_ip" { }

