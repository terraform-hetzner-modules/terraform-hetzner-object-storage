resource "minio_s3_bucket" "current" {
  for_each = local.buckets

  bucket         = local.names[each.key]
  bucket_prefix  = each.value.bucket_prefix
  force_destroy  = each.value.force_destroy
  object_locking = each.value.object_locking
  # The provider implements ACLs through policies. Keep this create-time baseline
  # fixed, and give all subsequent policy changes to the policy resource below.
  acl = "private"

  lifecycle {
    precondition {
      condition     = each.value.name == null || each.value.bucket_prefix == null
      error_message = "Set either name or bucket_prefix, never both."
    }
    precondition {
      condition = local.names[each.key] == null ? true : (
        can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", local.names[each.key])) &&
        !can(regex("\\.\\.|\\.-|-\\.|^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", local.names[each.key]))
      )
      error_message = "Bucket names must be 3-63 lowercase letters, digits, dots or hyphens, start/end with a letter or digit, and contain neither IP addresses nor adjacent dots/dot-hyphen combinations."
    }
    precondition {
      condition     = length(compact(values(local.names))) == length(distinct(compact(values(local.names))))
      error_message = "Explicit or derived bucket names must be unique."
    }
    precondition {
      condition     = contains(["private", "public-read"], each.value.acl)
      error_message = "acl must be private or public-read."
    }
    precondition {
      condition     = each.value.acl == "private" || !try(each.value.policy.enabled, false)
      error_message = "Use either public-read or a custom policy; put public access into the custom policy when needed."
    }
    precondition {
      condition     = !each.value.object_locking || try(each.value.versioning.status != "Suspended" || !each.value.versioning.enabled, true)
      error_message = "Object-locked buckets cannot suspend versioning."
    }
    precondition {
      condition     = each.value.object_locking || !try(each.value.retention.enabled, false)
      error_message = "Default retention requires object_locking=true at bucket creation."
    }
  }
}

resource "minio_s3_bucket_versioning" "current" {
  for_each = local.versioning
  bucket   = minio_s3_bucket.current[each.key].id
  versioning_configuration {
    status = each.value.status
  }
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "minio_s3_bucket_policy" "current" {
  for_each = local.policies
  bucket   = minio_s3_bucket.current[each.key].id
  policy = try(each.value.policy.enabled, false) ? each.value.policy.json : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadObjects"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["${minio_s3_bucket.current[each.key].arn}/*"]
    }]
  })
  dynamic "timeouts" {
    for_each = try(each.value.policy.timeouts, null) == null ? [] : [each.value.policy.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
  depends_on = [minio_s3_bucket_versioning.current]
  lifecycle {
    precondition {
      condition     = !try(each.value.policy.enabled, false) || can(jsondecode(each.value.policy.json).Statement)
      error_message = "An enabled policy must provide a JSON object containing Statement."
    }
  }
}

resource "minio_s3_bucket_object_lock_configuration" "current" {
  for_each            = local.retention
  bucket              = minio_s3_bucket.current[each.key].id
  object_lock_enabled = "Enabled"
  rule {
    default_retention {
      mode  = each.value.mode
      days  = each.value.days
      years = each.value.years
    }
  }
  depends_on = [minio_s3_bucket_versioning.current]
  lifecycle {
    precondition {
      condition     = (each.value.days == null ? 0 : 1) + (each.value.years == null ? 0 : 1) == 1
      error_message = "Retention requires exactly one of days or years."
    }
  }
}

resource "minio_s3_bucket_cors" "current" {
  for_each = { for key, bucket in local.buckets : key => bucket.cors_rules if length(bucket.cors_rules) > 0 }
  bucket   = minio_s3_bucket.current[each.key].id
  dynamic "cors_rule" {
    for_each = each.value
    content {
      id              = cors_rule.value.id
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = cors_rule.value.allowed_headers
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "minio_s3_bucket_lifecycle" "current" {
  for_each = { for key, bucket in local.buckets : key => bucket.lifecycle_rules if length(bucket.lifecycle_rules) > 0 }
  bucket   = minio_s3_bucket.current[each.key].id
  dynamic "rule" {
    for_each = each.value
    content {
      id     = rule.value.id
      status = rule.value.status
      dynamic "expiration" {
        for_each = rule.value.expiration == null ? [] : [rule.value.expiration]
        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration == null ? [] : [rule.value.noncurrent_version_expiration]
        content { noncurrent_days = noncurrent_version_expiration.value.noncurrent_days }
      }
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload == null ? [] : [rule.value.abort_incomplete_multipart_upload]
        content { days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation }
      }
      dynamic "filter" {
        for_each = rule.value.filter == null ? [] : [rule.value.filter]
        content {
          prefix                   = filter.value.prefix
          object_size_greater_than = filter.value.object_size_greater_than
          object_size_less_than    = filter.value.object_size_less_than
          dynamic "tag" {
            for_each = filter.value.tag == null ? [] : [filter.value.tag]
            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }
          dynamic "and" {
            for_each = filter.value.and == null ? [] : [filter.value.and]
            content {
              prefix                   = and.value.prefix
              tags                     = and.value.tags
              object_size_greater_than = and.value.object_size_greater_than
              object_size_less_than    = and.value.object_size_less_than
            }
          }
        }
      }
    }
  }
  depends_on = [minio_s3_bucket_versioning.current]
  lifecycle {
    precondition {
      condition     = length(each.value) == length(distinct([for rule in each.value : rule.id]))
      error_message = "Lifecycle rule IDs must be unique within each bucket."
    }
    precondition {
      condition     = alltrue([for rule in each.value : rule.noncurrent_version_expiration == null]) || local.buckets[each.key].object_locking || try(local.buckets[each.key].versioning.enabled && local.buckets[each.key].versioning.status == "Enabled", false)
      error_message = "Noncurrent expiration requires enabled versioning or object locking."
    }
  }
}
