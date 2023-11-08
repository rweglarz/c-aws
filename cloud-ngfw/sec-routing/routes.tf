data "cloudngfwaws_ngfw" "x" {
  name       = "${var.name}-tf"
  account_id = var.account_id
}

data "aws_subnet" "ngfw" {
  for_each = { for v in data.cloudngfwaws_ngfw.x.status[0].attachment : v.subnet_id => v }
  id       = each.key
}


locals {
  vpce-map = flatten([
    for s in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : [
      for a in data.cloudngfwaws_ngfw.x.status[0].attachment : {
        subnet_id         = s.id
        vpce              = a.endpoint_id
        availability_zone = s.availability_zone
      } if (data.aws_subnet.ngfw[a.subnet_id].availability_zone == s.availability_zone) && (length(regexall("-tgw", s.tags.Name)) > 0)
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

resource "aws_route" "tgwa-dg_via_vpce" {
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



resource "aws_route_table" "ngfw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : v.availability_zone => v if length(regexall("-ngfw", v.tags.Name)) > 0 }

  vpc_id = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.vpc.id
  tags = {
    Name = "${var.name}-ngfw-${each.key}"
  }
}

resource "aws_route_table_association" "ngfw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-ngfw", v.tags.Name)) > 0 }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.ngfw[each.value.availability_zone].id
}

resource "aws_route" "ngfw-172_via_tgw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-ngfw", v.tags.Name)) > 0 }

  route_table_id         = aws_route_table.ngfw[each.value.availability_zone].id
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = data.terraform_remote_state.tgw-ngfw.outputs.tgw-id
}

resource "aws_route" "ngfw-dg_via_natgw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-ngfw", v.tags.Name)) > 0 }

  route_table_id         = aws_route_table.ngfw[each.value.availability_zone].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.nat_gateways[each.value.availability_zone].id
}



resource "aws_route_table" "natgw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : v.availability_zone => v if length(regexall("-natgw", v.tags.Name)) > 0 }

  vpc_id = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.vpc.id
  tags = {
    Name = "${var.name}-natgw-${each.key}"
  }
}

resource "aws_route_table_association" "natgw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-natgw", v.tags.Name)) > 0 }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.natgw[each.value.availability_zone].id
}

resource "aws_route" "natgw-to_igw" {
  for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-natgw", v.tags.Name)) > 0 }

  route_table_id         = aws_route_table.natgw[each.value.availability_zone].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.internet_gateway_id
}

resource "aws_route" "natgw-to_vpce" {
  #for_each = { for k, v in data.terraform_remote_state.tgw-ngfw.outputs.vpc-sec.subnets : k => v if length(regexall("-natgw", v.tags.Name)) > 0 }
  for_each = { for k, v in local.vpce-map : v.availability_zone => v }

  route_table_id         = aws_route_table.natgw[each.key].id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = each.value.vpce
}
