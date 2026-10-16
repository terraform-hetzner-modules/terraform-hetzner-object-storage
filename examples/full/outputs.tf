output "names" {
  description = "Bucket names to use in application storage configuration."
  value       = module.storage.names
}
output "urls" {
  description = "Provider-reported bucket URLs keyed by application."
  value       = module.storage.urls
}
