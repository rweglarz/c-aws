module "vpc_prod_eu_central" {
  source = "../modules/vpc"
  providers = { aws = aws.eu-central-1 }

  name = "${var.name}-prod-eu-central"

  cidr_block              = local.cidr.prod_eu_central
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips.eu-central-1
  deploy_igw              = true

  routing_scenario = 6

  connect_cwan     = true
  core_network_id  = aws_networkmanager_core_network.this.id
  core_network_arn = aws_networkmanager_core_network.this.arn

  subnets = {
    "corea-a"    : { "idx" : 0, "zone" : "eu-central-1a" },
    "workload-a" : { "idx" : 1, "zone" : "eu-central-1a" },
  }
  tags = {
    env = "prod"
  }
}


module "vpc_prod_eu_west" {
  source = "../modules/vpc"
  providers = { aws = aws.eu-west-1 }

  name = "${var.name}-prod-eu-west"

  cidr_block              = local.cidr.prod_eu_west
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips.eu-west-1
  deploy_igw              = true

  routing_scenario = 6

  connect_cwan     = true
  core_network_id  = aws_networkmanager_core_network.this.id
  core_network_arn = aws_networkmanager_core_network.this.arn

  subnets = {
    "corea-a"    : { "idx" : 0, "zone" : "eu-west-1a" },
    "workload-a" : { "idx" : 1, "zone" : "eu-west-1a" },
  }
  tags = {
    env = "prod"
  }
}

