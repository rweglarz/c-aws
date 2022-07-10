data "cloudngfwaws_ngfw" "x" {
  name = "${var.name}-tf"
}

data "aws_subnet" "ngfw" {
  for_each = { for v in data.cloudngfwaws_ngfw.x.status[0].attachment : v.subnet_id => v }
  id       = each.key
}


locals {
  vpce-map = flatten([
    #s if length(regexall("tgw", s.tags.Name)) > 0
    for s in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : [
      for a in data.cloudngfwaws_ngfw.x.status[0].attachment : {
        subnet_id         = s.id
        vpce              = a.endpoint_id
        availability_zone = s.availability_zone
      } if (data.aws_subnet.ngfw[a.subnet_id].availability_zone == s.availability_zone) && (length(regexall("tgw", s.tags.Name)) > 0)
    ]
  ])
}

data "terraform_remote_state" "tgw-ngfw" {
  backend = "local"
  config = {
    path = "../tgw-ngfw/terraform.tfstate"
  }
}


resource "aws_route_table" "tgwa" {
  for_each = { for k, v in local.vpce-map : v.availability_zone => v }

  vpc_id = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.vpc.id
  tags = {
    Name = "${var.name}-tgwa-${each.key}"
  }
}
resource "aws_route" "to_vpce" {
  for_each = { for k, v in local.vpce-map : v.availability_zone => v }

  route_table_id         = aws_route_table.tgwa[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = each.value.vpce
}
resource "aws_route_table_association" "tgwa" {
  for_each = { for k, v in local.vpce-map : v.availability_zone => v }

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.tgwa[each.key].id
}

resource "aws_route_table_association" "ngfw" {
  for_each = { for k,v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets: k=>v if length(regexall("-ngfw", v.tags.Name)) > 0 }

  subnet_id      = each.value.id
  route_table_id = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.route_tables["via_tgw"]
}
