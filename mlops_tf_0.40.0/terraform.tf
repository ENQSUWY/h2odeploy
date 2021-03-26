terraform {
  required_version = ">= 0.13"

  required_providers {
    aws        = "2.26"
    kubernetes = "1.9"
    null       = "2.1"
    random     = "2.2"
    tls        = "2.1"
  }
}
