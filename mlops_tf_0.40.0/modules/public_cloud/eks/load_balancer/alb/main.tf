data "aws_vpc" "cluster" {
  id = var.vpc_id
}

data "aws_subnet_ids" "cluster" {
  vpc_id = var.vpc_id
}


resource "aws_security_group" "alb" {
  name        = var.name
  description = "Security group for ${var.name} ALB"
  vpc_id      = data.aws_vpc.cluster.id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.name
  }
}

resource "aws_lb" "lb" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnet_ids.cluster.ids

  ip_address_type = "ipv4"

  tags = {
    Name = var.name
  }
}

resource "aws_lb_listener" "https_redirect" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "target" {
  name     = var.name
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.cluster.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_security_group_rule" "alb_listener" {
  description       = "Open HTTPS on ${var.name}"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}
