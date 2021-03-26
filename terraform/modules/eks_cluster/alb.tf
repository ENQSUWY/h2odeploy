variable "domain" {
  description = "Domain suffix for all the deployed components."
}

resource "aws_security_group" "alb" {
  name        = "${local.cluster_name}-alb"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                          = "${local.cluster_name}-alb"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "alb_listener" {
  description       = "Open HTTPS"
  from_port         = 443
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]

}


resource "aws_acm_certificate" "traefik" {
  domain_name = "*.${var.prefix}.${var.domain}"

  validation_method = "DNS"

  tags = {
    Name                                          = "${var.prefix}-trafik-alb-cert"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"

  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "traefik" {
  name               = "${var.prefix}-traefik-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.node.id, aws_security_group.alb.id]
  subnets            = aws_subnet.demo[*].id
  ip_address_type    = "ipv4"

  tags = {
    Name                                          = "${var.prefix}-traefik-alb"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}


resource "aws_lb_listener" "traefik" {
  load_balancer_arn = aws_lb.traefik.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.traefik.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik.arn
  }
}

resource "aws_lb_listener" "traefik_redirect" {
  load_balancer_arn = aws_lb.traefik.arn
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

resource "aws_lb_target_group" "traefik" {
  name     = "${var.prefix}-traefik-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo.id
}


resource "aws_lb_target_group_attachment" "traefik_attachment" {
  count = var.node_count

  target_group_arn = aws_lb_target_group.traefik.arn
  target_id        = aws_instance.node[count.index].id
}

data "aws_route53_zone" "mm_route_zone" {
  name = "${var.domain}."
}

resource "aws_route53_record" "traefik_alias" {
  zone_id = data.aws_route53_zone.mm_route_zone.zone_id
  name    = "${var.prefix}.${var.domain}."
  type    = "A"

  alias {
    name                   = aws_lb.traefik.dns_name
    zone_id                = aws_lb.traefik.zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "traefik_wildcard" {
  zone_id = data.aws_route53_zone.mm_route_zone.zone_id
  name    = "*.${var.prefix}.${var.domain}."
  type    = "CNAME"
  ttl     = 30
  records = ["${aws_route53_record.traefik_alias.fqdn}."]
}

resource "aws_route53_record" "traefik_validation" {
  zone_id = data.aws_route53_zone.mm_route_zone.zone_id
  name    = aws_acm_certificate.traefik.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.traefik.domain_validation_options[0].resource_record_type
  ttl     = 30
  records = [aws_acm_certificate.traefik.domain_validation_options[0].resource_record_value]
}

output "alb_base_hostname" {
  value = "${var.prefix}.${var.domain}"
}

output "alb_model_hostname" {
  value = "model.${var.prefix}.${var.domain}"
}
