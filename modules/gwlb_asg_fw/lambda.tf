resource "aws_iam_role" "lambda_iam_role" {
  name = "${var.name}-lambda_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name = "${var.name}-lambda_iam_policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:AssignIpv6Addresses",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:CreateTags",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:TerminateInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "lambda_payload.zip"
}
resource "aws_lambda_function" "eni_lambda" {
  role    = aws_iam_role.lambda_iam_role.arn
  handler = "lambda.lambda_handler"
  runtime = "python3.8"
  timeout = 90

  source_code_hash = data.archive_file.lambda.output_base64sha256
  filename         = "lambda_payload.zip"
  function_name    = "${var.name}-eni"

  environment {
    variables = {
      subnet_ids = join(",", concat(local.di1_eni_subnet_ids, local.di2_eni_subnet_ids))
      di1_sg_ids = join(",", local.di1_sg_ids)
      di2_sg_ids = join(",", local.di2_sg_ids)
      ipv6       = var.dual_stack ? "true" : "false"
      interfaces = jsonencode({for k,v in var.interfaces: v.device_index => v})
    }
  }
}

resource "aws_cloudwatch_event_rule" "watch_asg" {
  name        = "${var.name}-event-rule"
  description = var.name

  event_pattern = jsonencode({
    source = [
      "aws.autoscaling"
    ]
    detail = {
      AutoScalingGroupName = [
        aws_autoscaling_group.this.name
      ]
    }
    detail-type = [
      "EC2 Instance-launch Lifecycle Action",
      "EC2 Instance-terminate Lifecycle Action"
    ]
  })
}

resource "aws_cloudwatch_event_target" "tl" {
  target_id = "${var.name}-et"
  rule      = aws_cloudwatch_event_rule.watch_asg.name
  arn       = aws_lambda_function.eni_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "${var.name}-lp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eni_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.watch_asg.arn
}
