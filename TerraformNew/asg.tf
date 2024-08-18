resource "aws_launch_template" "aws-ec2-lt" {
  name          = "aws-ec2-lt"
  image_id      = data.aws_ami.app-ec2-ami.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "aws-ec2-lt-g"
    }
  }
}




resource "aws_autoscaling_group" "aws-ec2-asg" {

  launch_template {
    id      = aws_launch_template.aws-ec2-lt.id
    version = "$Latest"
  }

  max_size         = var.max_size 
  min_size         = var.min_size
  desired_capacity = var.desired_size

  vpc_zone_identifier = aws_subnet.app-vpc-public-subnet.*.id

  tag {
    key                 = "Name"
    value               = "AWS-EC2-ASG"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  force_delete              = false
  health_check_grace_period = 300

}


resource "aws_autoscaling_policy" "AWS-EC2-Scale-UP" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.aws-ec2-asg.name

}

resource "aws_autoscaling_policy" "AWS-EC2-Scale-Down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.aws-ec2-asg.name

}

resource "aws_launch_configuration" "name" {
  name_prefix   = "terraform-lc-example-"
  image_id      = data.aws_ami.app-ec2-ami.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}