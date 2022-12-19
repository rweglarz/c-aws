resource "aws_iam_policy" "flow-logs" {
  name = "${var.name}-flow_logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "flow-logs" {
  name = "${var.name}-flow_logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Principal : {
          Service : "vpc-flow-logs.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "flow-logs" {
  role       = aws_iam_role.flow-logs.name
  policy_arn = aws_iam_policy.flow-logs.arn
}
