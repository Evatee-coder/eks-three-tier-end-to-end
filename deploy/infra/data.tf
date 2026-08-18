data "aws_eks_cluster" "eks" {
  name = "eks-terraform-two-tier-app"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "eks-terraform-two-tier-app"
}

#data.aws_eks_cluster.eks.endpoint

# Look up existing pod execution role by name
data "aws_iam_role" "fargate_pod_execution" {
  name = "pod-execution-role"  
}