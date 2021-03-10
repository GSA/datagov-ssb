output "app_id" {
  description = "The ID of the cloudfoundry_app that was created"
  value       = cloudfoundry_app.ssb.id
}

output "broker_registrations" {
  value       = [ 
    cloudfoundry_service_broker.space_scoped_broker.*.id, 
    cloudfoundry_service_broker.standard_broker.*.id 
  ]
}