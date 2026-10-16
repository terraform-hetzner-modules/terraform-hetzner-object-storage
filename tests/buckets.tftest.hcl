mock_provider "minio" {}

run "empty" {
  command = plan
  assert {
    condition     = length(output.names) == 0
    error_message = "The empty module must create nothing."
  }
}
run "names_and_defaults" {
  command = plan
  variables {
    name_prefix = "my-observability-"
    defaults    = { force_destroy = true, versioning = {} }
    buckets = {
      loki    = { force_destroy = false }
      tempo   = { name = "my-explicit-tempo", versioning = { enabled = false } }
      scratch = { bucket_prefix = "my-scratch-" }
    }
  }
  assert {
    condition     = output.names.loki == "my-observability-loki" && output.names.tempo == "my-explicit-tempo"
    error_message = "Names must use caller keys and exact overrides."
  }
  assert {
    condition     = !minio_s3_bucket.current["loki"].force_destroy && minio_s3_bucket.current["tempo"].force_destroy
    error_message = "Explicit false must override shared true."
  }
  assert {
    condition     = toset(keys(minio_s3_bucket_versioning.current)) == toset(["loki", "scratch"]) && minio_s3_bucket.current["scratch"].bucket_prefix == "my-scratch-"
    error_message = "Versioning opt-out and provider-generated name prefixes must work."
  }
}
run "full_configuration" {
  command = plan
  variables {
    defaults = {
      versioning      = { timeouts = { create = "5m", read = "2m", update = "5m", delete = "5m" } }
      cors_rules      = [{ allowed_methods = ["GET"], allowed_origins = ["https://example.com"], max_age_seconds = 60 }]
      lifecycle_rules = [{ id = "multipart", abort_incomplete_multipart_upload = { days_after_initiation = 7 } }]
    }
    buckets = {
      loki = {
        name           = "my-full-loki"
        object_locking = true
        retention      = { mode = "GOVERNANCE", days = 7 }
        policy = {
          json     = <<-JSON
            {"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":["s3:GetObject"],"Resource":["arn:aws:s3:::my-full-loki/*"]}]}
          JSON
          timeouts = { create = "4m", read = "2m", update = "4m", delete = "4m" }
        }
        lifecycle_rules = [
          { id = "current", filter = { prefix = "logs/" }, expiration = { days = 30 } },
          { id = "noncurrent", noncurrent_version_expiration = { noncurrent_days = 7 } },
          { id = "markers", expiration = { expired_object_delete_marker = true } },
          { id = "sized", filter = { and = { prefix = "tmp/", object_size_greater_than = 100, object_size_less_than = 1000 } }, expiration = { date = "2030-01-01" } }
        ]
      }
      tempo = {
        cors_rules      = []
        lifecycle_rules = []
        versioning      = { status = "Suspended" }
      }
    }
  }
  assert {
    condition     = length(minio_s3_bucket_cors.current) == 1 && minio_s3_bucket_cors.current["loki"].cors_rule[0].max_age_seconds == 60
    error_message = "An empty per-bucket list must clear inherited CORS."
  }
  assert {
    condition     = length(minio_s3_bucket_lifecycle.current) == 1 && length(minio_s3_bucket_lifecycle.current["loki"].rule) == 4
    error_message = "Lifecycle lists must replace shared lists as a whole."
  }
  assert {
    condition     = minio_s3_bucket_versioning.current["tempo"].versioning_configuration[0].status == "Suspended" && minio_s3_bucket_versioning.current["tempo"].timeouts == null
    error_message = "Nested configuration overrides must replace shared objects as a whole."
  }
  assert {
    condition     = minio_s3_bucket_object_lock_configuration.current["loki"].rule[0].default_retention[0].days == 7 && minio_s3_bucket_policy.current["loki"].timeouts.create == "4m"
    error_message = "Retention and operation timeouts must reach their resources."
  }
}
run "public_policy" {
  command = apply
  variables {
    buckets = { public = { name = "my-public-assets", acl = "public-read" } }
  }
  assert {
    condition     = jsondecode(minio_s3_bucket_policy.current["public"].policy).Statement[0].Resource[0] == "${output.arns.public}/*" && minio_s3_bucket.current["public"].acl == "private"
    error_message = "Public access must be managed by exactly one policy resource."
  }
}
run "private_again" {
  command = plan
  variables {
    buckets = { public = { name = "my-public-assets", acl = "private" } }
  }
  assert {
    condition     = length(minio_s3_bucket_policy.current) == 0
    error_message = "Returning to private must remove the managed public policy."
  }
}
run "disable_optional_defaults" {
  command = plan
  variables {
    defaults = {
      object_locking = true
      retention      = { years = 1 }
      policy         = { json = "{}" }
    }
    buckets = { logs = { retention = { enabled = false }, policy = { enabled = false } } }
  }
  assert {
    condition     = length(minio_s3_bucket_policy.current) == 0 && length(minio_s3_bucket_object_lock_configuration.current) == 0
    error_message = "enabled=false must opt out of shared optional configurations."
  }
}
run "disabled_module" {
  command = plan
  variables {
    create  = false
    buckets = { logs = {} }
  }
  assert {
    condition     = length(output.buckets) == 0
    error_message = "create=false must disable all resources."
  }
}

run "reject_conflicting_names" {
  command = plan
  variables {
    buckets = { logs = { name = "my-logs", bucket_prefix = "logs-" } }
  }
  expect_failures = [minio_s3_bucket.current["logs"]]
}

run "reject_invalid_name" {
  command = plan
  variables {
    buckets = { logs = { name = "Invalid_Name" } }
  }
  expect_failures = [minio_s3_bucket.current["logs"]]
}

run "reject_duplicate_names" {
  command = plan
  variables {
    buckets = { first = { name = "my-logs" }, second = { name = "my-logs" } }
  }
  expect_failures = [minio_s3_bucket.current["first"], minio_s3_bucket.current["second"]]
}

run "reject_policy_acl_conflict" {
  command = plan
  variables {
    buckets = { logs = { acl = "public-read", policy = { json = "{\"Statement\":[]}" } } }
  }
  expect_failures = [minio_s3_bucket.current["logs"]]
}

run "reject_retention_without_lock" {
  command = plan
  variables {
    buckets = { logs = { retention = { days = 7 } } }
  }
  expect_failures = [minio_s3_bucket.current["logs"]]
}

run "reject_suspended_lock" {
  command = plan
  variables {
    buckets = { logs = { object_locking = true, versioning = { status = "Suspended" } } }
  }
  expect_failures = [minio_s3_bucket.current["logs"]]
}

run "reject_retention_periods" {
  command = plan
  variables {
    buckets = { logs = { object_locking = true, retention = { days = 7, years = 1 } } }
  }
  expect_failures = [minio_s3_bucket_object_lock_configuration.current["logs"]]
}

run "reject_policy_without_statement" {
  command = plan
  variables {
    buckets = { logs = { policy = { json = "{}" } } }
  }
  expect_failures = [minio_s3_bucket_policy.current["logs"]]
}

run "reject_noncurrent_without_versioning" {
  command = plan
  variables {
    buckets = { logs = { lifecycle_rules = [{ id = "old", noncurrent_version_expiration = { noncurrent_days = 7 } }] } }
  }
  expect_failures = [minio_s3_bucket_lifecycle.current["logs"]]
}

run "reject_null_bucket" {
  command = plan
  variables {
    buckets = { logs = null }
  }
  expect_failures = [var.buckets]
}
