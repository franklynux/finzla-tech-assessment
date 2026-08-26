# Create Application Load Balncer Security Group
resource "aws_security_group" "alb_sg" {
  name = "App-LB-SG"
  description = "Security group for the Application Load Balancer"
    tags = {
      Name = "Finzla-Tech"
    }
}

# Allow inbound HTTP inbound traffic
resource "aws_security_group_rule" "allow_inbound_http" {
  type = "ingress"
  protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb_sg.id
}


resource "aws_lb" "app_lb" {
  name               = "HTTP-service-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  ip_address_type    = "ipv4"
  enable_http2       = true
  idle_timeout       = 60

  enable_deletion_protection = false

  tags = {
    Name = "Finzla-Tech"
  }
}

#Target Group Configuration
resource "aws_lb_target_group" "alb_tg" {
  name     ="HTTP-service-TG"
  port     = 8000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  depends_on = [aws_lb.app_lb]
  deregistration_delay = 120

  tags = {
    Name = "Finzla-Tech"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  depends_on = [aws_lb.app_lb]
}