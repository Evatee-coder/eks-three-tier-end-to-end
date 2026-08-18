module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.5.0"

  name               = "eks-terraform-two-tier-app" #"${var.project}-${var.environment}-ekspart5"
  kubernetes_version = "1.31"

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id

  # private subnet id for eks control and node
  subnet_ids = module.vpc.private_subnets
  # control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }


  # Fargate Profile(s)
  fargate_profiles = {
    for-fargate = {
      name = "fargate-profile"
      selectors = [
        {
          namespace = "for-fargate"
        }
      ]
      subnet_ids = module.vpc.private_subnets

      create_iam_role = false
      iam_role_arn    = data.aws_iam_role.fargate_pod_execution.arn
    }
  }

  tags = {
    #Environment = "dev"
    Terraform = "true"
    repo      = "eks-terraform-two-tier-app"
  }
}