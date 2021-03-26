resource "grafanaauth_api_key" "admin_key" {
  name = var.admin_key_name
  role = "Admin"
}

resource "grafanaauth_api_key" "viewer_key" {
  name = var.viewer_key_name
  role = "Viewer"
}
