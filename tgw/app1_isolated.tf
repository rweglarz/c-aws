module "vpc-app11" {
  source = "../modules/vpc"

  name = "${var.name}-app11"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = false
  routing_scenario = 2

  gwlb_service_name = module.mfw.aws_vpc_endpoint_service_name

  subnets = {
    "workload-a" : { "idx" : 0, "zone" : var.availability_zones[0] },
    "gwlbe-a"    : { "idx" : 1, "zone" : var.availability_zones[0], tags = { pan_zone: "env1" } },
  }
}


module "vpc-app12" {
  source = "../modules/vpc"

  name = "${var.name}-app12"

  cidr_block              = var.app1_cidr
  public_mgmt_prefix_list = var.pl-mgmt-mgmt_ips

  deploy_igw  = true
  connect_tgw = false
  routing_scenario = 2

  gwlb_service_name = module.mfw.aws_vpc_endpoint_service_name

  subnets = {
    "workload-b" : { "idx" : 0, "zone" : var.availability_zones[1] },
    "gwlbe-b"    : { "idx" : 1, "zone" : var.availability_zones[1], tags = { pan_zone: "env2" } },
  }
  tags = {
    pan_zone = "overlapping001a"
  }
}



resource "aws_instance" "app11_workload" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  vpc_security_group_ids = [module.vpc-app11.sg_public_id]
  subnet_id              = module.vpc-app11.subnets["workload-a"].id

  private_ip                  = cidrhost(module.vpc-app11.subnets["workload-a"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app11"
  }
}



resource "aws_instance" "app12_workload" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  vpc_security_group_ids = [module.vpc-app12.sg_public_id]
  subnet_id              = module.vpc-app12.subnets["workload-b"].id

  private_ip                  = cidrhost(module.vpc-app12.subnets["workload-b"].cidr_block, 5)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name}-app12"
  }
}



resource "aws_route53_record" "app1" {
  for_each = {
    app11 = aws_instance.app11_workload.public_ip 
    app12 = aws_instance.app12_workload.public_ip
  }
  zone_id = data.aws_route53_zone.w-aws.zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [
    each.value
  ]
}
