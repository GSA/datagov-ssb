output "app_id" {
  description = "The ID of the cloudfoundry_app that was created"
  value       = cloudfoundry_app.ssb.id
}
