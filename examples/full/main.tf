module "storage" {
  source      = "../.."
  name_prefix = var.name_prefix
  defaults = {
    versioning = {}
    lifecycle_rules = [{
      id                                = "abort-incomplete-uploads"
      abort_incomplete_multipart_upload = { days_after_initiation = 7 }
    }]
  }
  buckets = {
    loki  = { versioning = { enabled = false } }
    tempo = { versioning = { enabled = false } }
    assets = {
      # An exact name lets this policy refer to the bucket without a module cycle.
      name = "${var.name_prefix}assets"
      policy = {
        json = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Sid       = "ReadPublicAssets"
            Effect    = "Allow"
            Principal = "*"
            Action    = ["s3:GetObject"]
            Resource  = ["arn:aws:s3:::${var.name_prefix}assets/*"]
          }]
        })
      }
      cors_rules = [{
        id              = "web"
        allowed_origins = ["https://example.com"]
        allowed_methods = ["GET", "HEAD"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3600
      }]
    }
    archive = {
      object_locking = true
      retention      = { mode = "GOVERNANCE", days = 7 }
      lifecycle_rules = [
        { id = "expire-current", expiration = { days = 30 } },
        { id = "expire-noncurrent", noncurrent_version_expiration = { noncurrent_days = 7 } },
        { id = "abort-uploads", abort_incomplete_multipart_upload = { days_after_initiation = 7 } }
      ]
    }
    manual = { lifecycle_rules = [], versioning = { enabled = false } }
  }
}
