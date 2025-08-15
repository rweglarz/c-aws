module "eks_c1" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = "${var.name}-c1"

  kubernetes_version = var.k8s_version

  vpc_id = module.vpc_eks.vpc.id
  control_plane_subnet_ids = [
    for k, v in module.vpc_eks.subnets : v.id if length(regexall("k8s-cp-", k)) > 0
  ]
  subnet_ids = [
    for k, v in module.vpc_eks.subnets : v.id if length(regexall("k8s-n-", k)) > 0
  ]

  addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa_role_c1.arn
    }
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {
      before_compute = true
    }
  }


  endpoint_public_access_cidrs = concat(
    [for k, v in var.mgmt_ips : v.cidr],
    [for ip in [var.panorama_ip] : "${ip}/32"],
  )
  endpoint_public_access  = true #just to have it explicitly
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

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
        ng = "default"
      }
    }
    # ng1 = {
    #   desired_size         = 1
    #   instance_types       = ["t3.xlarge"]
    #   ami_type             = "BOTTLEROCKET_x86_64"
    #   platform             = "bottlerocket"
    #   bootstrap_extra_args = <<-EOT
    #   [settings.host-containers.admin]
    #   enabled = true
    #   EOT
    #   labels = {
    #     ng = "ng1"
    #   }
    # }
  }
}


module "ebs_csi_irsa_role_c1" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name             = "ebs-csi-c1"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks_c1.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

