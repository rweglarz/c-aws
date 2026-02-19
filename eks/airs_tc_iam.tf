locals {
  tc_role_name   = "private_cluster_role"
  tc_policy_name = "airs-tag-collector"
}

resource "aws_iam_role" "airs_tag_collector" {
  name = local.tc_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.tc_instances.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "airs" {
  name        = local.tc_policy_name
  description = "Policy for airs tag collector private k8s access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "eks:AccessKubernetesApi",
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.airs_tag_collector.name
  policy_arn = aws_iam_policy.airs.arn
}
