variable "create" {
  description = "Whether to manage the configured buckets and their settings. Setting false plans removal of existing resources."
  type        = bool
  default     = true
  nullable    = false
}
variable "name_prefix" {
  description = "Literal prefix for names derived from map keys. Exact names and bucket_prefix override it; no random suffix is added."
  type        = string
  default     = ""
  nullable    = false
}
variable "defaults" {
  description = "Shared bucket settings. Non-null per-bucket fields override these. Nested objects and lists are replaced as a whole; empty lists clear inherited rules, and enabled=false disables an inherited optional configuration."
  type = object({

    acl            = optional(string, "private")
    force_destroy  = optional(bool, false)
    object_locking = optional(bool, false)
    versioning = optional(object({
      enabled  = optional(bool, true)
      status   = optional(string, "Enabled")
      timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) }))
    }))
    policy = optional(object({
      enabled  = optional(bool, true)
      json     = optional(string)
      timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) }))
    }))
    retention = optional(object({
      enabled = optional(bool, true)
      mode    = optional(string, "GOVERNANCE")
      days    = optional(number)
      years   = optional(number)
    }))
    cors_rules = optional(list(object({
      id              = optional(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
    lifecycle_rules = optional(list(object({
      id     = string
      status = optional(string, "Enabled")
      filter = optional(object({
        prefix                   = optional(string)
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        tag                      = optional(object({ key = string, value = string }))
        and = optional(object({
          prefix                   = optional(string)
          tags                     = optional(map(string))
          object_size_greater_than = optional(number)
          object_size_less_than    = optional(number)
        }))
      }))
      expiration = optional(object({
        days                         = optional(number)
        date                         = optional(string)
        expired_object_delete_marker = optional(bool)
      }))
      noncurrent_version_expiration     = optional(object({ noncurrent_days = number }))
      abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number }))
    })), [])
  })
  default  = {}
  nullable = false
}
variable "buckets" {
  description = "Buckets keyed by stable identifiers known at plan time. Names default to name_prefix plus the key. Set name for an exact name, or bucket_prefix for a provider-generated suffix. Optional configuration presence/enabled flags and rule counts must be known at plan time; names and policy JSON may be computed."
  type = map(object({
    name          = optional(string)
    bucket_prefix = optional(string)

    acl            = optional(string)
    force_destroy  = optional(bool)
    object_locking = optional(bool)
    versioning = optional(object({
      enabled  = optional(bool, true)
      status   = optional(string, "Enabled")
      timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) }))
    }))
    policy = optional(object({
      enabled  = optional(bool, true)
      json     = optional(string)
      timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) }))
    }))
    retention = optional(object({
      enabled = optional(bool, true)
      mode    = optional(string, "GOVERNANCE")
      days    = optional(number)
      years   = optional(number)
    }))
    cors_rules = optional(list(object({
      id              = optional(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    lifecycle_rules = optional(list(object({
      id     = string
      status = optional(string, "Enabled")
      filter = optional(object({
        prefix                   = optional(string)
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        tag                      = optional(object({ key = string, value = string }))
        and = optional(object({
          prefix                   = optional(string)
          tags                     = optional(map(string))
          object_size_greater_than = optional(number)
          object_size_less_than    = optional(number)
        }))
      }))
      expiration = optional(object({
        days                         = optional(number)
        date                         = optional(string)
        expired_object_delete_marker = optional(bool)
      }))
      noncurrent_version_expiration     = optional(object({ noncurrent_days = number }))
      abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number }))
    })))
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for bucket in var.buckets : bucket != null])
    error_message = "Bucket entries must be objects, not null."
  }
}
