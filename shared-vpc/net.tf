module "vpc" {
  source   = "../modules/vpc"
  providers = { aws = aws.network }

  name = "${var.name}-vpc"

  cidr_block              = cidrsubnet(var.cidr, 0, 0)
  public_mgmt_prefix_list = aws_ec2_managed_prefix_list.mgmt_ips.id
  deploy_igw              = true
  deploy_natgw            = false

  connect_tgw             = false

  subnets = {
    "workload-1" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "workload-2" : { "idx" : 1, "zone" : var.availability_zones[0] },
  }
}

resource "aws_route_table_association" "workload-1" {
  provider          = aws.network

  route_table_id = module.vpc.route_tables.via_igw
  subnet_id      = module.vpc.subnets.workload-1.id
}

resource "aws_route_table_association" "workload-2" {
  provider          = aws.network

  route_table_id = module.vpc.route_tables.via_igw
  subnet_id      = module.vpc.subnets.workload-2.id
}

resource "aws_ram_resource_share" "subnet1" {
  provider          = aws.network

  name  = "${var.name}-subnet-1"

  allow_external_principals = false
}

resource "aws_ram_principal_association" "subnet1" {
  provider          = aws.network

  resource_share_arn = aws_ram_resource_share.subnet1.arn
  principal          = var.account_ids.workload-1
}

resource "aws_ram_resource_association" "subnet1" {
  provider          = aws.network

  resource_share_arn = aws_ram_resource_share.subnet1.arn
  resource_arn       = module.vpc.subnets.workload-1.arn
}
