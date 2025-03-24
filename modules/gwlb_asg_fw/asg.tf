locals {
  primary_eni_subnets    = one([for k, v in var.interfaces : v.subnet_id if v.device_index == 0]) 
  primary_eni_subnet_ids = flatten([for k, v in local.primary_eni_subnets : v])
  primary_sg_ids         = one([for k, v in var.interfaces : v.security_group_ids if v.device_index == 0])
}

resource "aws_autoscaling_group" "this" {
  name                = var.name
  vpc_zone_identifier = local.primary_eni_subnet_ids

  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = 0
  placement_group           = aws_placement_group.this.id
  health_check_grace_period = var.health_check_grace_period

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
  # initial_lifecycle_hook {
  #   name                 = "lh_launch"
  #   default_result       = "ABANDON"
  #   heartbeat_timeout    = 300
  #   lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  # }
}

resource "aws_autoscaling_lifecycle_hook" "lh_launch" {
  name                   = "${var.name}-lh_launch"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "lh_terminate" {
  name                   = "${var.name}-lh_terminate"
  autoscaling_group_name = aws_autoscaling_group.this.name
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_launch_template" "this" {
  name          = var.name
  ebs_optimized = true

  image_id      = coalesce(var.fw_ami_id, data.aws_ami.pa_vm.id)
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
    subnet_id       = local.primary_eni_subnet_ids[0]
    security_groups = local.primary_sg_ids
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
