module "eks_c1" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.name}-1"
  cluster_version = var.k8s_version

  vpc_id = module.vpc_eks.vpc.id
  subnet_ids = [
    for k, v in module.vpc_eks.subnets : v.id if length(regexall("k8s", k)) > 0
  ]

  cluster_addons = {
    # coredns = {
    #   most_recent = true
    # }
    # kube-proxy = {
    #   most_recent = true
    # }
    # vpc-cni = {
    #   most_recent = true
    # }
  }


  cluster_endpoint_public_access_cidrs = [for k, v in var.mgmt_ips : v.cidr]
  cluster_endpoint_public_access       = true #just to have it explicitly
  cluster_endpoint_private_access      = true

  manage_aws_auth_configmap = true

  node_security_group_additional_rules = {
    r1 = {
      protocol  = 6
      from_port = 22
      to_port   = 22
      type      = "ingress"
      cidr_blocks = [
        module.vpc_eks.subnets["mgmt"].cidr_block
      ]
    }
  }

  eks_managed_node_groups = {
    default_node_group = {
      desired_size               = 2
      instance_types             = ["t3.2xlarge"]
      use_custom_launch_template = false

      remote_access = {
        ec2_ssh_key = var.key_name
      }
      labels = {
        ng = "def"
      }
    }
    cnng = {
      desired_size         = 2
      instance_types       = ["t3.2xlarge"]
      ami_type             = "BOTTLEROCKET_x86_64"
      platform             = "bottlerocket"
      bootstrap_extra_args = <<-EOT
      [settings.host-containers.admin]
      enabled = true

      [settings.kubernetes.node-labels]
      nge = "cne"
      EOT
      labels = {
        ng = "cn"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "cn-series"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}


provider "kubernetes" {
  host                   = module.eks_c1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_c1.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_c1.cluster_name]
  }
}

