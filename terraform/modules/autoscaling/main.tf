# Auto Scaling Module - Notes CRUD
# Free Tier: min=1, max=1, desired=1 (single instance for cost control)

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  asg_name = "${var.environment}-notes-crud-asg"
}

# Auto Scaling Group
resource "aws_autoscaling_group" "notes_crud" {
  name                = local.asg_name
  vpc_zone_identifier = var.vpc_zone_identifier

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  target_group_arns = var.target_group_arns

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # Termination policies
  termination_policies = ["Default"]

  # Tags
  tag {
    key                 = "Name"
    value               = local.asg_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_capacity,
    ]
  }
}

# Scale-down protection (not needed for min=max=1 but good practice)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.asg_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.notes_crud.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.asg_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.notes_crud.name
}

# CloudWatch metric alarms for scaling (optional - not used with min=max=1)
# Included for completeness if min/max are changed in future

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.asg_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up if CPU > 70% for 2 periods"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.notes_crud.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.asg_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down if CPU < 20% for 2 periods"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.notes_crud.name
  }
}