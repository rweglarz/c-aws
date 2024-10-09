resource "aws_iam_policy" "account1" {
  name = "${var.name}-cngfw-policy-tf"
  provider = aws.my-account1

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcEndpoints",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "account1" {
  name = "${var.name}-cngfw-role-tf"
  provider = aws.my-account1

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${cloudngfwaws_account.account1.trusted_account}:root"
        },
        Action : "sts:AssumeRole"
        Condition: {
            StringEquals: {
                "sts:ExternalId": cloudngfwaws_account.account1.external_id
            }
        }
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "account1" {
  provider = aws.my-account1
  role       = aws_iam_role.account1.name
  policy_arn = aws_iam_policy.account1.arn
}

output "account1-endpoint-role" {
  value = aws_iam_role.account1.arn
}
