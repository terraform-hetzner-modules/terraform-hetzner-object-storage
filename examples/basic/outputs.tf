output "names" {
  description = "Bucket names keyed by caller identifiers."
  value       = module.storage.names
}
output "urls" {
  description = "Provider-reported bucket URLs keyed by caller identifiers."
  value       = module.storage.urls
}
