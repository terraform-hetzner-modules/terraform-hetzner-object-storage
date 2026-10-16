module "storage" {
  source = "../.."

  create      = true
  name_prefix = var.name_prefix

  # Every shared setting is explicit. The documents bucket inherits them all.
  defaults = {
    acl            = "private"
    force_destroy  = false
    object_locking = true
    versioning = {
      enabled  = true
      status   = "Enabled"
      timeouts = { create = "5m", read = "2m", update = "5m", delete = "5m" }
    }
    policy = {
      enabled = true
      json = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Principal = "*"
          Action    = ["s3:*"]
          Resource  = ["arn:aws:s3:::${var.name_prefix}documents", "arn:aws:s3:::${var.name_prefix}documents/*"]
          Condition = { Bool = { "aws:SecureTransport" = "false" } }
        }]
      })
      timeouts = { create = "5m", read = "2m", update = "5m", delete = "5m" }
    }
    retention = {
      enabled = true
      mode    = "GOVERNANCE"
      days    = 7
      years   = null # Exactly one of days or years; see archive for years.
    }
    cors_rules = [{
      id              = "read-documents"
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["Authorization", "Range"]
      expose_headers  = ["ETag", "Content-Length"]
      max_age_seconds = 3600
    }]
    # One condition per top-level filter, or an AND block for combinations.
    lifecycle_rules = [
      {
        id         = "expire-by-prefix"
        status     = "Enabled"
        filter     = { prefix = "temporary/" }
        expiration = { days = 30 }
      },
      {
        id         = "expire-on-date"
        status     = "Disabled"
        filter     = { prefix = "migration/" }
        expiration = { date = "2035-01-01" }
      },
      {
        id         = "expire-tagged-objects"
        status     = "Enabled"
        filter     = { tag = { key = "retention", value = "short" } }
        expiration = { days = 90 }
      },
      {
        id         = "expire-large-objects"
        status     = "Enabled"
        filter     = { object_size_greater_than = 1073741824 }
        expiration = { days = 180 }
      },
      {
        id         = "expire-small-objects"
        status     = "Enabled"
        filter     = { object_size_less_than = 1024 }
        expiration = { days = 180 }
      },
      {
        id     = "expire-matching-objects"
        status = "Enabled"
        filter = {
          and = {
            prefix                   = "exports/"
            tags                     = { retention = "short", category = "generated" }
            object_size_greater_than = 1024
            object_size_less_than    = 10485760
          }
        }
        expiration = { days = 90 }
      },
      {
        id                            = "expire-old-versions"
        status                        = "Enabled"
        noncurrent_version_expiration = { noncurrent_days = 30 }
      },
      {
        id         = "remove-expired-markers"
        status     = "Enabled"
        expiration = { expired_object_delete_marker = true }
      },
      {
        id                                = "abort-incomplete-uploads"
        status                            = "Enabled"
        abort_incomplete_multipart_upload = { days_after_initiation = 7 }
      }
    ]
  }

  buckets = {
    documents = {} # Derived name; inherits every shared setting.

    archive = {
      name           = "${var.name_prefix}archive"
      bucket_prefix  = null # Mutually exclusive with an exact name.
      acl            = "private"
      force_destroy  = false
      object_locking = true
      versioning = {
        enabled  = true
        status   = "Enabled"
        timeouts = { create = "10m", read = "3m", update = "10m", delete = "10m" }
      }
      policy = {
        enabled = true
        json = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Sid       = "DenyInsecureTransport"
            Effect    = "Deny"
            Principal = "*"
            Action    = ["s3:*"]
            Resource  = ["arn:aws:s3:::${var.name_prefix}archive", "arn:aws:s3:::${var.name_prefix}archive/*"]
            Condition = { Bool = { "aws:SecureTransport" = "false" } }
          }]
        })
        timeouts = { create = "10m", read = "3m", update = "10m", delete = "10m" }
      }
      retention = {
        enabled = true
        mode    = "GOVERNANCE"
        days    = null
        years   = 1
      }
      cors_rules = [{
        id              = "archive-downloads"
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["https://archive.example.com"]
        allowed_headers = ["Authorization", "Range"]
        expose_headers  = ["ETag", "Content-Length", "Content-Range"]
        max_age_seconds = 0 # An explicit zero is preserved.
      }]
      # Replaces the entire shared list, rather than merging individual rules.
      lifecycle_rules = [
        {
          id         = "expire-by-prefix"
          status     = "Enabled"
          filter     = { prefix = "temporary/" }
          expiration = { days = 400 }
        },
        {
          id         = "expire-on-date"
          status     = "Disabled"
          filter     = { prefix = "migration/" }
          expiration = { date = "2035-01-01" }
        },
        {
          id         = "expire-tagged-objects"
          status     = "Enabled"
          filter     = { tag = { key = "retention", value = "short" } }
          expiration = { days = 400 }
        },
        {
          id         = "expire-large-objects"
          status     = "Enabled"
          filter     = { object_size_greater_than = 1073741824 }
          expiration = { days = 400 }
        },
        {
          id         = "expire-small-objects"
          status     = "Enabled"
          filter     = { object_size_less_than = 1024 }
          expiration = { days = 400 }
        },
        {
          id     = "expire-matching-objects"
          status = "Enabled"
          filter = {
            and = {
              prefix                   = "exports/"
              tags                     = { retention = "short", category = "generated" }
              object_size_greater_than = 1024
              object_size_less_than    = 10485760
            }
          }
          expiration = { days = 400 }
        },
        {
          id                            = "expire-old-versions"
          status                        = "Enabled"
          noncurrent_version_expiration = { noncurrent_days = 400 }
        },
        {
          id         = "remove-expired-markers"
          status     = "Enabled"
          expiration = { expired_object_delete_marker = true }
        },
        {
          id                                = "abort-incomplete-uploads"
          status                            = "Enabled"
          abort_incomplete_multipart_upload = { days_after_initiation = 7 }
        }
      ]
    }

    downloads = {
      name            = "${var.name_prefix}downloads"
      acl             = "public-read" # Generated public policy instead of a custom policy.
      object_locking  = false
      versioning      = { enabled = true, status = "Suspended" }
      policy          = { enabled = false }
      retention       = { enabled = false }
      cors_rules      = []
      lifecycle_rules = []
    }

    temporary = {
      name            = null
      bucket_prefix   = "${var.name_prefix}tmp-" # Provider appends a unique suffix.
      acl             = "private"
      force_destroy   = true # This bucket is disposable, including its objects.
      object_locking  = false
      versioning      = { enabled = false }
      policy          = { enabled = false }
      retention       = { enabled = false }
      cors_rules      = []
      lifecycle_rules = []
    }
  }
}
