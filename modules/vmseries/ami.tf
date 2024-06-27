data "aws_ami" "pa_vm_byol" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["6njl1pau431dv1qxipg63mvah"]
  }
  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
  #name_regex       = "^myami-\\d{3}"
}


data "aws_ami" "pa_vm_bnd2" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["hd44w1chf26uv4p52cdynb2o"]
  }
  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
}

