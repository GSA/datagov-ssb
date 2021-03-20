output "app_id" {
  description = "The ID of the cloudfoundry_app that was created"
  value       = cloudfoundry_app.ssb.id
}

output "plans" {
  value = cloudfoundry_service_broker.space_scoped_broker["${var.broker_space.org}/${var.broker_space.space}"].service_plans
}