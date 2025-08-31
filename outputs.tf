output "name" {
  value = {
    for region, service in google_cloud_run_v2_service.cloudrun :
    region => service.name
  }
}

output "backend" {
  value = var.skipNeg ? "" : google_compute_backend_service.backend[0].id
}

output "urls" {
  value = {
    for region, service in google_cloud_run_v2_service.cloudrun :
    region => service.uri
  }
}

output "url" {
  value = values(google_cloud_run_v2_service.cloudrun)[0].uri
}

output "gsaEmail" {
  value = data.google_service_account.service_account.email
}

output "gsa" {
  value = data.google_service_account.service_account.name
}
