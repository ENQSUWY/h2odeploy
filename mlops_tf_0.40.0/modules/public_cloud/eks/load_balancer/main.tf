module "tls" {
  source = "./tls"

  route_zone = var.route_zone
  domain     = var.domain
}


module "alb" {
  source = "./alb"

  name        = var.name
  target_port = var.target_port

  certificate_arn = module.tls.certificate_arn
  vpc_id          = var.vpc_id
}


module "dns" {
  source = "./dns"

  route_zone        = var.route_zone
  domain            = var.domain
  load_balancer_arn = module.alb.load_balancer_arn
}
