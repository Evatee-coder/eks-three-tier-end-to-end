# GitHub Actions -> AWS OIDC federation
#
# Lets the CI workflow (.github/workflows/3tier-build.yaml) assume an AWS role
# via short-lived federated tokens instead of static access keys.
#
# The OIDC provider and role already exist in AWS (created manually, originally
# for a different repo - "part5-github-oidc-aws"). The `import` blocks
# below bring them under Terraform instead of recreating them. Run `terraform
# plan` first: it will show the trust-policy fix (repo condition corrected to
# this repo) and a tag cleanup, both non-destructive.

data "aws_caller_identity" "current" {}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

import {
  to = aws_iam_openid_connect_provider.github_actions
  id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

  tags = {
    Name = "github-actions-oidc-provider"
  }
}

import {
  to = aws_iam_role.github_actions_build
  id = "eks-github-actions-build-role"
}

resource "aws_iam_role" "github_actions_build" {
  name = "eks-github-actions-build-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Evatee-coder/eks-three-tier-end-to-end:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-eks-build-role"
  }
}

import {
  to = aws_iam_role_policy_attachment.github_actions_ecr
  id = "eks-github-actions-build-role/arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/eks-ECRPushPullPolicy"
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/eks-ECRPushPullPolicy"
}
