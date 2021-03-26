data "aws_route53_zone" "zone" {
  name = var.route_zone
}

data "aws_lb" "lb" {
  arn = var.load_balancer_arn
}

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = data.aws_lb.lb.dns_name
    zone_id                = data.aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "*.${var.domain}"
  type    = "CNAME"
  ttl     = 30
  records = ["${aws_route53_record.alias.fqdn}."]
}
