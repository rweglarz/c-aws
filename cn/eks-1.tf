module "eks_c1" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.name}-c1"
  cluster_version = var.k8s_version

  vpc_id = module.vpc_eks.vpc.id
  control_plane_subnet_ids = [
    for k, v in module.vpc_eks.subnets : v.id if length(regexall("k8s-cp-", k)) > 0
  ]
  subnet_ids = [
    for k, v in module.vpc_eks.subnets : v.id if length(regexall("k8s-n-", k)) > 0
  ]

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role_c1.iam_role_arn
    }
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


  cluster_endpoint_public_access_cidrs = concat(
    [for k, v in var.mgmt_ips : v.cidr],
    [for ip in [var.panorama1_ip, var.panorama2_ip] : "${ip}/32"],
  )
  cluster_endpoint_public_access  = true #just to have it explicitly
  cluster_endpoint_private_access = true

  manage_aws_auth_configmap = false

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


module "ebs_csi_irsa_role_c1" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "ebs-csi-c1"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks_c1.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}



# provider "kubernetes" {
#   host                   = module.eks_c1.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks_c1.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks_c1.cluster_name]
#   }
# }

