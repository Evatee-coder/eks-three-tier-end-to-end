provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      project = "EKS Cluster Setup and Two-Tier Deployment"
    }
  }

}


# The kubernetes provider to interact with EKS cluster. 
# It must be used after creating EKS cluster (i.e CLUSTER MUST BE CREATED BEFORE THIS PROVIDER below IS USED)

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}