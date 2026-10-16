output "buckets" {
  description = "Complete bucket resource attributes keyed by caller identifiers."
  value       = module.storage.buckets
}

output "ids" {
  description = "Bucket IDs keyed by caller identifiers."
  value       = module.storage.ids
}

output "names" {
  description = "Resolved bucket names keyed by caller identifiers."
  value       = module.storage.names
}

output "arns" {
  description = "Bucket ARNs for use in policy documents."
  value       = module.storage.arns
}

output "urls" {
  description = "Provider-reported bucket URLs keyed by caller identifiers."
  value       = module.storage.urls
}
