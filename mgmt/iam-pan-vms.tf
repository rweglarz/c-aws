resource "aws_iam_role" "pan_ha" {
  name = "${var.name}-pan_ha"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role" "pan_gwlb" {
  name = "${var.name}-pan_gwlb"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "pan_ha" {
  name = "${var.name}-pan_ha"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AssignPrivateIpAddresses",
          "ec2:AssociateAddress",
          "ec2:DescribeRouteTables",
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action   = "ec2:ReplaceRoute"
        Resource = "arn:aws:ec2:*:*:route-table/*"
        Effect   = "Allow"
      },
    ]
  })
}
resource "aws_iam_policy" "pan_cloudwatch" {
  name = "${var.name}-pan_cloudwatch"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ha-ha" {
  role       = aws_iam_role.pan_ha.name
  policy_arn = aws_iam_policy.pan_ha.arn
}
resource "aws_iam_role_policy_attachment" "ha-cloudwatch" {
  role       = aws_iam_role.pan_ha.name
  policy_arn = aws_iam_policy.pan_cloudwatch.arn
}
resource "aws_iam_role_policy_attachment" "gwlb-cloudwatch" {
  role       = aws_iam_role.pan_gwlb.name
  policy_arn = aws_iam_policy.pan_cloudwatch.arn
}

resource "aws_iam_instance_profile" "pan_ha" {
  name = "${var.name}-pan_ha"
  role = aws_iam_role.pan_ha.name
}
resource "aws_iam_instance_profile" "pan_gwlb" {
  name = "${var.name}-pan_gwlb"
  role = aws_iam_role.pan_gwlb.name
}

output "instance_profile-pan_ha" {
  value = aws_iam_instance_profile.pan_ha.arn
}
output "instance_profile-pan_gwlb" {
  value = aws_iam_instance_profile.pan_gwlb.arn
}
