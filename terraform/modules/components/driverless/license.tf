locals {
  license_secret_name = "${var.prefix}-driverless-license"
}

resource "kubernetes_secret" "driverless_license" {
  metadata {
    namespace = var.namespace
    name      = local.license_secret_name
  }

  data = {
    "license.sig" = file(var.driverless_license_path)
  }
}
