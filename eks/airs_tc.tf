#region tc vm
module "airs_tc" {
  count  = var.airs_tc_bootstrap != null ? 1 : 0
  source = "../modules/vmseries"

  name             = "${var.name}-airs-tc"
  fw_instance_type = "c6i.xlarge"
  ami              = var.airs_tc_ami[var.region]

  iam_instance_profile = aws_iam_instance_profile.tc.name

  key_pair = var.key_pair

  bootstrap_options = var.airs_tc_bootstrap

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.vpc_eks.subnets["mgmt"].id
      private_ip   = cidrhost(module.vpc_eks.subnets["mgmt"].cidr_block, 6)
      security_group_ids = [
        module.vpc_eks.security_group_ids.public_mgmt,
        module.vpc_eks.security_group_ids.private,
        module.vpc_eks.security_group_ids.outbound,
      ]
    }
  }
}
#endregion


#region iam
resource "aws_iam_role" "tc_instances" {
  name = "${var.name}-tc-instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service= "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_instance_profile" "tc" {
  name = aws_iam_role.tc_instances.name
  role = aws_iam_role.tc_instances.name
  path = "/"
}
#endregion

