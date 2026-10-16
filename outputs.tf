output "buckets" {
  description = "Complete bucket attributes indexed by stable caller keys, after all managed bucket settings are applied."
  value       = minio_s3_bucket.current
  depends_on  = [minio_s3_bucket_versioning.current, minio_s3_bucket_policy.current, minio_s3_bucket_object_lock_configuration.current, minio_s3_bucket_cors.current, minio_s3_bucket_lifecycle.current]
}
output "ids" {
  description = "Bucket IDs indexed by stable caller keys."
  value       = { for key, bucket in minio_s3_bucket.current : key => bucket.id }
  depends_on  = [minio_s3_bucket_versioning.current, minio_s3_bucket_policy.current, minio_s3_bucket_object_lock_configuration.current, minio_s3_bucket_cors.current, minio_s3_bucket_lifecycle.current]
}

output "names" {
  description = "Bucket names indexed by stable caller keys."
  value       = { for key, bucket in minio_s3_bucket.current : key => bucket.bucket }
  depends_on  = [minio_s3_bucket_versioning.current, minio_s3_bucket_policy.current, minio_s3_bucket_object_lock_configuration.current, minio_s3_bucket_cors.current, minio_s3_bucket_lifecycle.current]
}

output "arns" {
  description = "Bucket ARNs for policy statements indexed by stable caller keys."
  value       = { for key, bucket in minio_s3_bucket.current : key => bucket.arn }
  depends_on  = [minio_s3_bucket_versioning.current, minio_s3_bucket_policy.current, minio_s3_bucket_object_lock_configuration.current, minio_s3_bucket_cors.current, minio_s3_bucket_lifecycle.current]
}

output "urls" {
  description = "Provider-reported bucket URLs indexed by stable caller keys."
  value       = { for key, bucket in minio_s3_bucket.current : key => bucket.bucket_domain_name }
  depends_on  = [minio_s3_bucket_versioning.current, minio_s3_bucket_policy.current, minio_s3_bucket_object_lock_configuration.current, minio_s3_bucket_cors.current, minio_s3_bucket_lifecycle.current]
}
