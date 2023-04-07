data "aws_ami" "pa_vm" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["6njl1pau431dv1qxipg63mvah"]
  }
  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
}

resource "aws_placement_group" "this" {
  name         = var.name
  strategy     = "spread"
  spread_level = "rack"
}

resource "aws_autoscaling_group" "this" {
  name                = var.name
  vpc_zone_identifier = aws_subnet.fw[*].id

  desired_capacity          = var.desired_capacity
  max_size                  = 4
  min_size                  = 0
  placement_group           = aws_placement_group.this.id
  health_check_grace_period = 1300

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [
      target_group_arns,
      desired_capacity,
    ]
  }
  }
}

resource "aws_security_group" "fw" {
  description = "allow all traffic for fw"
  vpc_id      = aws_vpc.this.id
  name        = "${var.name}-mgmt-pub"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}"
  }
}


resource "aws_launch_template" "this" {
  name          = var.name
  ebs_optimized = true

  image_id      = data.aws_ami.pa_vm.id
  instance_type = var.fw_instance_type
  iam_instance_profile {
    arn = var.iam_instance_profile
  }

  key_name = var.key_pair

  user_data = base64encode(join("\n", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  ))))

  network_interfaces {
    device_index    = 0
    subnet_id       = aws_subnet.fw[0].id
    security_groups = [aws_security_group.fw.id]
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp2"
      delete_on_termination = "true"
      volume_size           = 60
    }
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  lb_target_group_arn    = aws_lb_target_group.this.arn
}
