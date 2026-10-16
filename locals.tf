locals {
  buckets = {
    for key, bucket in var.buckets : key => merge(bucket, {
      for field, fallback in var.defaults : field => bucket[field] != null ? bucket[field] : fallback
    }) if var.create && bucket != null
  }
  names = {
    for key, bucket in local.buckets : key => (
      bucket.bucket_prefix != null ? null : (bucket.name != null ? bucket.name : "${var.name_prefix}${key}")
    )
  }
  versioning = { for key, bucket in local.buckets : key => bucket.versioning if try(bucket.versioning.enabled, false) }
  policies = {
    for key, bucket in local.buckets : key => bucket
    if bucket.acl == "public-read" || try(bucket.policy.enabled, false)
  }
  retention = { for key, bucket in local.buckets : key => bucket.retention if try(bucket.retention.enabled, false) }
}
