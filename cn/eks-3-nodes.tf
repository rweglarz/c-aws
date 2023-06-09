data "aws_ami" "eks" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.24-v2023*"]
  }
}


resource "aws_iam_role" "eks_ir" {
  name = "${var.name}-eks_ir"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess",
  ]
}
resource "aws_iam_role_policy" "eks_iam_role_policy" {
  name = "${var.name}-eks_iam_role_policy"
  role = aws_iam_role.eks_ir.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:ModifyInstanceAttribute",
          "ec2:ReplaceRoute",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eks_ip" {
  name = "${var.name}-eks_ip"
  role = aws_iam_role.eks_ir.name
}

locals {
  cluster_name = "${var.name}-c3"
  nkv = { for k, v in var.hsf_nodes : k => {
    cluster_name = local.cluster_name
    labels = join(",", [for lk,lv in v.labels: "${lk}=${lv}"] )
    }
  }
}

data "template_cloudinit_config" "k8s" {
  for_each          = var.hsf_nodes
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path        = "/var/lib/cloud/scripts/per-once/k8s.sh"
          content     = templatefile("${path.module}/init/k8s.sh.tfpl", local.nkv[each.key])
          permissions = "0744"
        },
      ]
      packages = [
        "git",
        "golang",
        "net-tools",
        "pciutils",
        "tcpdump",
      ]
    })
  }
}

resource "aws_network_interface" "k8s-m" {
  for_each          = var.hsf_nodes
  subnet_id         = module.vpc_eks.subnets["k8s-m-a"].id
  source_dest_check = false
  security_groups = [
    module.vpc_eks.sg_private_id,
    module.eks_c3.cluster_primary_security_group_id,
  ]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_network_interface" "k8s-ci" {
  for_each          = var.hsf_nodes
  subnet_id         = module.vpc_eks.subnets["k8s-ci-a"].id
  source_dest_check = false
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_instance" "k8s-nodes" {
  for_each      = var.hsf_nodes
  ami           = data.aws_ami.eks.id
  instance_type = each.value.instance_type
  key_name      = var.key_name

  iam_instance_profile = aws_iam_instance_profile.eks_ip.id

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.k8s-m[each.key].id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.k8s-ci[each.key].id
  }
  # network_interface {
  #   device_index         = 2
  #   network_interface_id = module.vpc_eks.subnets["k8s-ti-a"].id
  # }


  user_data_base64            = data.template_cloudinit_config.k8s[each.key].rendered
  user_data_replace_on_change = true

  tags = {
    Name                                          = "${var.name}-${each.key}"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}

