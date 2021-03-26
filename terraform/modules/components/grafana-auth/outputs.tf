output "admin_api_key" {
  value     = grafanaauth_api_key.admin_key.key
  sensitive = true
}

output "viewer_api_key" {
  value     = grafanaauth_api_key.viewer_key.key
  sensitive = true
}
