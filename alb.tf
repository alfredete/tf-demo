
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "ALB security group to scaling group"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP traffic to scaling group"
    Location = "Public"
  }
}


resource "aws_lb" "load_balancer" {
  name = "appLB"
  #expuesto públicamente
  internal = false

  security_groups = [aws_security_group.alb_sg.id]
  load_balancer_type = "application"

  subnets = [aws_subnet.public_subnet_b.id, aws_subnet.public_subnet_a.id]


  #si queremos balancear entre difierentes availability zones
  enable_cross_zone_load_balancing   = true

}

/* for testing purposes
resource "aws_lb_listener" "lb_listener_http" {

  load_balancer_arn = aws_lb.load_balancer.arn

  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HELLO!"
      status_code  = "200"
    }
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}
*/


resource "aws_lb_listener" "lb_listener_http" {

  load_balancer_arn = aws_lb.load_balancer.arn

  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}


resource "aws_lb_target_group" "lb_target_group" {

  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id



  depends_on = [
    aws_lb.load_balancer,
  ]
  deregistration_delay    = 90

health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  alb_target_group_arn = aws_lb_target_group.lb_target_group.arn
}
