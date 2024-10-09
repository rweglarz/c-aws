resource "aws_iam_policy" "account2" {
  name = "${var.name}-cngfw-policy-tf"
  provider = aws.my-account2

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:CreateFunction",
          "iam:GetRole",
          "lambda:AddPermission",
          "cloudformation:ListStacks",
          "cloudformation:CreateStack",
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "iam:CreateRole",
          "iam:DeleteRole",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:GetTemplate",
          "cloudformation:DeleteStack",
          "lambda:DeleteFunction",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "account2" {
  name = "${var.name}-cngfw-role-tf"
  provider = aws.my-account2

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Principal : {
          AWS : var.user_arn
        },
        Action : "sts:AssumeRole"
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "account2" {
  provider = aws.my-account2
  role       = aws_iam_role.account2.name
  policy_arn = aws_iam_policy.account2.arn
}

