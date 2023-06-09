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
  kv = {
    cluster_name = "${var.name}-c3"
  }
}

data "template_cloudinit_config" "k8s" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path        = "/var/lib/cloud/scripts/per-once/k8s.sh"
          content     = templatefile("${path.module}/init/k8s.sh.tfpl", local.kv)
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

resource "aws_network_interface" "k8s-gw-m" {
  count             = 1
  subnet_id         = module.vpc_eks.subnets["k8s-m-a"].id
  source_dest_check = false
  security_groups = [
    module.vpc_eks.sg_private_id,
    module.eks_c3.cluster_primary_security_group_id,
  ]
}

resource "aws_network_interface" "k8s-ci-m" {
  count             = 1
  subnet_id         = module.vpc_eks.subnets["k8s-ci-a"].id
  source_dest_check = false
}

resource "aws_instance" "k8s-gw" {
  count         = 1
  ami           = data.aws_ami.eks.id
  instance_type = "c5n.4xlarge"
  key_name      = var.key_name

  iam_instance_profile = aws_iam_instance_profile.eks_ip.id

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.k8s-gw-m[count.index].id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.k8s-ci-m[count.index].id
  }
  # network_interface {
  #   device_index         = 2
  #   network_interface_id = module.vpc_eks.subnets["k8s-ti-a"].id
  # }


  user_data_base64 = data.template_cloudinit_config.k8s.rendered
  user_data_replace_on_change = true

  tags = {
    Name                                   = "${var.name}-gw-${count.index}"
    "kubernetes.io/cluster/${var.name}-c3" = "owned"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}

