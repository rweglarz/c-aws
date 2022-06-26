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
  source_file = "../modules/gwlb_asg_fw/lambda.py"
  output_path = "../modules/gwlb_asg_fw/lambda_payload.zip"
}
resource "aws_lambda_function" "eni_lambda" {
  role    = aws_iam_role.lambda_iam_role.arn
  handler = "lambda.lambda_handler"
  runtime = "python3.8"
  timeout = 60

  source_code_hash = data.archive_file.lambda.output_base64sha256
  filename         = "../modules/gwlb_asg_fw/lambda_payload.zip"
  function_name    = "${var.name}-eni"

  environment {
    variables = {
      subnet_ids = join(",", concat(aws_subnet.mgmt[*].id, aws_subnet.untrust[*].id))
      sg_ids     = join(",", [aws_security_group.fw.id, aws_security_group.fw.id])
    }
  }
}

resource "aws_cloudwatch_event_rule" "watch_asg" {
  name        = "${var.name}-eventrule"
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

resource "aws_autoscaling_lifecycle_hook" "lh_launch" {
  name                   = "${var.name}-lh_launch"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}
/*
resource "aws_autoscaling_lifecycle_hook" "lh_terminate" {
  name                   = "${var.name}-lh_terminate"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}
*/

