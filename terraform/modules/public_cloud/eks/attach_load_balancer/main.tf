data "aws_lb_target_group" "node" {
  arn = var.load_balancer_target_group_arn
}

resource "aws_autoscaling_attachment" "attach" {
  autoscaling_group_name = var.autoscaling_group_name
  alb_target_group_arn   = data.aws_lb_target_group.node.arn
}


resource "aws_security_group_rule" "forward" {
  description              = "Allow to ALB to forward to the port"
  from_port                = var.port
  protocol                 = "tcp"
  security_group_id        = var.target_security_group_id
  source_security_group_id = var.load_balancer_security_group_id
  to_port                  = var.port
  type                     = "ingress"
}
