resource "kubernetes_namespace" "ns" {
  metadata {

    labels = {
      mylabel = "simple-nginx"
    }

    name = "simple-nginx"
  }
}


resource "aws_eks_fargate_profile" "fargate" {
  cluster_name           = data.aws_eks_cluster.eks.name
  fargate_profile_name   = kubernetes_namespace.ns.metadata[0].name #implicit dependency on the namespace resource
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  # subnet_ids             = ["subnet-0932365a17a1851a7", "subnet-0d4c547b2537b7240", "subnet-09e00173bae0586b7"]
  subnet_ids             = data.aws_eks_cluster.eks.vpc_config[0]["subnet_ids"]

  selector {
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
}

#the resources below is k8s deployment that deploy nginx image on the namespace created above.

# Deploys nginx (2 replicas) into the target namespace, running on Fargate.
# Uses POD AFFINITY (not anti-affinity) to prefer co-locating nginx pods
# on the same node — note: this reduces HA since a single node failure
# could take down both replicas. Confirm this is intentional.

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {

        affinity {
          pod_affinity {

            # ✅ preferred uses weight + pod_affinity_term
            preferred_during_scheduling_ignored_during_execution {

              # Weight ranges from 1 to 100
              # Higher weight = higher priority/preference
              weight = 100

              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["nginx"]
                  }
                }
                # Same node scheduling
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          name  = "nginx"
          image = "nginx:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [aws_eks_fargate_profile.fargate]
}


# Use the created IAM role as the pod_execution_role_arn in the Fargate profile
# Update the aws_eks_fargate_profile resource to reference this role:
# pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
    name = "${data.aws_eks_cluster.eks.name}-fargate-pod-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks-fargate-pods.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    role       = aws_iam_role.eks_fargate_pod_execution_role.name
}







# resource "kubernetes_deployment" "nginx" {
#   metadata {
#     name      = "nginx"
#     namespace = kubernetes_namespace.ns.metadata[0].name
#     labels = {
#       app = "nginx"
#     }
#   }

#   spec {
#     replicas = 2

#     selector {
#       match_labels = {
#         app = "nginx"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "nginx"
#         }
#       }

#       spec {
#         container {
#           name  = "nginx"
#           image = "nginx:latest"

#           port {                    # ✅ singular, not ports
#             container_port = 80
#           }
#         }
#       }
#     }
#   }

#   depends_on = [aws_eks_fargate_profile.fargate]
# }



































