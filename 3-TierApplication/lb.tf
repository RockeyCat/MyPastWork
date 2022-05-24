resource "aws_lb" "app-alb" {
  name               = "App-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-vpc-ec2-sg.id, ]
  subnets            = aws_subnet.app-vpc-public-subnet.*.id
}

resource "aws_lb_target_group" "app-alb-tg" {
  name     = "app-alb-tg"
  port     = var.port
  protocol = var.protocol
  vpc_id   = aws_vpc.app-vpc.id
}

resource "aws_lb_target_group_attachment" "app-alb-tg-a" {
  count            = length(aws_instance.web-ec2)
  target_group_arn = aws_lb_target_group.app-alb-tg.arn
  target_id        = element(aws_instance.web-ec2.*.id, count.index)
  port             = var.port
}

resource "aws_lb_listener" "app-lb-l" {
  load_balancer_arn = aws_lb.app-alb.arn
  port              = var.port
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-alb-tg.arn
  }
}