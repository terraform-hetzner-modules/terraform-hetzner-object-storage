# Hetzner Object Storage Terraform module

Terraform module to manage multiple Hetzner S3 buckets with shared defaults and per-bucket settings.
Supports versioning, bucket policies, CORS, lifecycle rules, and object-lock retention through the
`aminueza/minio` provider.

## Usage

Copy this module configuration into `main.tf` and replace `my-company-storage-` with your own unique
prefix. Add the [provider configuration](#provider-configuration) below in `versions.tf`.

```hcl
module "storage" {
  source = "terraform-hetzner-modules/object-storage/hetzner"

  name_prefix = "my-company-storage-"
  defaults = {
    versioning = { status = "Enabled" }
  }
  buckets = {
    documents = {}
    uploads = {
      versioning = { enabled = false }
      cors_rules = [{
        allowed_origins = ["https://example.com"]
        allowed_methods = ["GET", "PUT"]
        allowed_headers = ["Content-Type"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3600
      }]
      lifecycle_rules = [{
        id                                = "abort-incomplete-uploads"
        abort_incomplete_multipart_upload = { days_after_initiation = 7 }
      }]
    }
  }
}

output "bucket_names" {
  value = module.storage.names
}
```

Both buckets are private. `documents` inherits versioning; `uploads` disables it and adds browser
access rules and incomplete-upload cleanup. CORS does not grant access: browser requests still need
authentication. Replace the example origin with your own domain.

## Provider configuration

Create S3 credentials in the Hetzner Console and export the access key as `MINIO_USER` and the secret
key as `MINIO_PASSWORD`. Put the following in your calling root's `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.45"
    }
  }
}

provider "minio" {
  minio_server        = "fsn1.your-objectstorage.com"
  minio_region        = "fsn1"
  minio_ssl           = true
  skip_bucket_tagging = true
  s3_compat_mode      = true
}
```

With both files in place, run `terraform init`, `terraform plan`, and `terraform apply`.
Credentials and provider configuration belong in the calling root. The provider connects directly
to Hetzner's S3 API; no MinIO server is required. See
[Hetzner's Terraform guide](https://docs.hetzner.com/storage/object-storage/getting-started/creating-a-bucket-minio-terraform/)
for credential setup and endpoint details.

## Examples

- [Basic](examples/basic): multiple private buckets using a shared naming prefix.
- [Full](examples/full): every module input and nested field, including shared defaults, overrides,
  naming alternatives, policy and versioning timeouts, CORS, lifecycle filters, and retention.

## Configuration

### Bucket names and shared defaults

Use stable keys in `buckets`; they identify Terraform resource addresses. Names default to
`name_prefix + key`. Set `name` for an exact name, or `bucket_prefix` for a provider-generated suffix.
These naming alternatives are mutually exclusive. Names are not silently normalized.

Non-null per-bucket settings override `defaults`. Nested objects and lists replace shared values as
a whole. Explicit `false`, zero where valid, and empty lists are preserved. Use `cors_rules = []` or
`lifecycle_rules = []` to clear inherited rules, and `{ enabled = false }` to disable inherited
`versioning`, `policy`, or `retention` configuration. Null inherits the shared value.

By default, buckets are private, `force_destroy` and `object_locking` are false, and no optional
configuration resources are created. `versioning = {}` enables versioning. Empty `buckets` creates
nothing. Setting `create = false` disables all resources and plans destruction of existing ones.

Keys, optional configuration presence/enabled flags, and rule counts must be known at plan time.
Names, rule values, and policy JSON can be computed. Keep the collection and its keys non-sensitive;
credentials belong in the provider configuration.

### Access policies

`acl = "public-read"` creates a policy granting public object reads. For custom access, set
`policy = { json = jsonencode(...) }` instead. Use a single custom document when combining public
access and other permissions. Custom policies and `public-read` cannot be enabled together.

The provider implements its ACL setting through bucket policies. The module uses a fixed private
creation baseline and a separate policy resource for subsequent public/custom access. Returning to
`private` or disabling a custom policy deletes that managed policy. A default private bucket without
a managed policy does not reconcile policies added outside Terraform.

Use exact bucket names in custom policy ARNs (`arn:aws:s3:::<bucket-name>/*`); referencing this module's
outputs in its own inputs creates a dependency cycle. Generated names cannot be referenced in a
custom policy within the same call. The built-in public-read policy supports generated names.

Hetzner keys can access all buckets in their project by default. For per-key restrictions, use
[Hetzner's documented policy principals](https://docs.hetzner.com/storage/object-storage/faq/s3-credentials/).
Private visibility alone does not isolate keys within a project.

### Retention and lifecycle rules

Use lifecycle rules for expiration, noncurrent-version cleanup, and incomplete multipart uploads.
Rules support prefix, object-tag, and size filters. Coordinate expiration with any other process
that manages data retention. For multiple filter conditions use `filter.and`; expiration by days,
date, and expired delete markers are separate alternatives.

Object locking must be selected at bucket creation and cannot subsequently be disabled. It enables
versioning automatically. Default retention requires locking and exactly one of `days` or `years`.
The provider does not force replacement when `object_locking` changes; toggling the flag is not a
migration procedure. Removing managed versioning attempts to suspend it, which locked buckets may
reject. Removing retention settings does not remove existing objects' individual retention locks.

### Referencing buckets

`names`, `ids`, `arns`, `urls`, and complete `buckets` attributes use the caller's map keys. Outputs
wait for all managed bucket settings. Use `module.storage.names.documents` to reference a bucket.
`urls` contains provider-reported path-style URLs, not hostnames. The raw `buckets` attributes include
the private creation baseline even when a separate policy grants public access.

## Notes

- Each provider configuration selects one credential/project pair and one regional endpoint:
  `fsn1`, `nbg1`, or `hel1`. Use separate calls with aliased providers for multiple projects or regions.
- Removing a bucket entry plans destruction. Nonempty buckets block deletion unless `force_destroy`
  was enabled before removal. Retention may still prevent deletion, including with force destruction.
- Changing an exact name replaces storage without migrating objects. Generated prefixes are
  create-only; changing a prefix may not replace or rename an existing bucket.
- Bucket tags, MinIO admin quotas, replication, storage-class transitions, newer-noncurrent-version
  counts, and MinIO-specific versioning exclusions are not exposed. See
  [Hetzner's supported actions](https://docs.hetzner.com/storage/object-storage/supported-actions/).
- Credentials, object uploads, and Terraform backend configuration are managed outside this module.

## Import

Configure the matching bucket entry, then import it using its existing name:

```hcl
import {
  to = module.storage.minio_s3_bucket.current["documents"]
  id = "my-company-storage-documents"
}
```

Import existing configured child resources separately, also using the bucket name. For example:
`module.storage.minio_s3_bucket_versioning.current["documents"]` and
`module.storage.minio_s3_bucket_policy.current["documents"]`. CORS, lifecycle, and object-lock
configuration support the same import identifier. Import before applying to an existing bucket;
creating it afresh can overwrite its existing policy with the private creation baseline.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.7 |
| minio | ~> 3.45 |

## Providers

| Name | Version |
| ---- | ------- |
| minio | ~> 3.45 |

## Resources

| Name | Type |
| ---- | ---- |
| [minio_s3_bucket.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket) | resource |
| [minio_s3_bucket_cors.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket_cors) | resource |
| [minio_s3_bucket_lifecycle.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket_lifecycle) | resource |
| [minio_s3_bucket_object_lock_configuration.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [minio_s3_bucket_policy.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket_policy) | resource |
| [minio_s3_bucket_versioning.current](https://registry.terraform.io/providers/aminueza/minio/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| buckets | Buckets keyed by stable identifiers known at plan time. Names default to name\_prefix plus the key. Set name for an exact name, or bucket\_prefix for a provider-generated suffix. Optional configuration presence/enabled flags and rule counts must be known at plan time; names and policy JSON may be computed. | ```map(object({ name = optional(string) bucket_prefix = optional(string) acl = optional(string) force_destroy = optional(bool) object_locking = optional(bool) versioning = optional(object({ enabled = optional(bool, true) status = optional(string, "Enabled") timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) policy = optional(object({ enabled = optional(bool, true) json = optional(string) timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) retention = optional(object({ enabled = optional(bool, true) mode = optional(string, "GOVERNANCE") days = optional(number) years = optional(number) })) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) }))) lifecycle_rules = optional(list(object({ id = string status = optional(string, "Enabled") filter = optional(object({ prefix = optional(string) object_size_greater_than = optional(number) object_size_less_than = optional(number) tag = optional(object({ key = string, value = string })) and = optional(object({ prefix = optional(string) tags = optional(map(string)) object_size_greater_than = optional(number) object_size_less_than = optional(number) })) })) expiration = optional(object({ days = optional(number) date = optional(string) expired_object_delete_marker = optional(bool) })) noncurrent_version_expiration = optional(object({ noncurrent_days = number })) abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number })) }))) }))``` | `{}` | no |
| create | Whether to manage the configured buckets and their settings. Setting false plans removal of existing resources. | `bool` | `true` | no |
| defaults | Shared bucket settings. Non-null per-bucket fields override these. Nested objects and lists are replaced as a whole; empty lists clear inherited rules, and enabled=false disables an inherited optional configuration. | ```object({ acl = optional(string, "private") force_destroy = optional(bool, false) object_locking = optional(bool, false) versioning = optional(object({ enabled = optional(bool, true) status = optional(string, "Enabled") timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) policy = optional(object({ enabled = optional(bool, true) json = optional(string) timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) retention = optional(object({ enabled = optional(bool, true) mode = optional(string, "GOVERNANCE") days = optional(number) years = optional(number) })) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) })), []) lifecycle_rules = optional(list(object({ id = string status = optional(string, "Enabled") filter = optional(object({ prefix = optional(string) object_size_greater_than = optional(number) object_size_less_than = optional(number) tag = optional(object({ key = string, value = string })) and = optional(object({ prefix = optional(string) tags = optional(map(string)) object_size_greater_than = optional(number) object_size_less_than = optional(number) })) })) expiration = optional(object({ days = optional(number) date = optional(string) expired_object_delete_marker = optional(bool) })) noncurrent_version_expiration = optional(object({ noncurrent_days = number })) abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number })) })), []) })``` | `{}` | no |
| name\_prefix | Literal prefix for names derived from map keys. Exact names and bucket\_prefix override it; no random suffix is added. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arns | Bucket ARNs for policy statements indexed by stable caller keys. |
| buckets | Complete bucket attributes indexed by stable caller keys, after all managed bucket settings are applied. |
| ids | Bucket IDs indexed by stable caller keys. |
| names | Bucket names indexed by stable caller keys. |
| urls | Provider-reported bucket URLs indexed by stable caller keys. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for local checks and contribution guidelines, and
[UPGRADING.md](docs/UPGRADING.md) for compatibility and live acceptance checks. The generated
[schema report](docs/SCHEMA.md) documents provider coverage and intentional omissions.

## Authors

Maintained by [Terraform Hetzner Modules](https://github.com/terraform-hetzner-modules).
See [AUTHORS](.github/AUTHORS) and [CODEOWNERS](.github/CODEOWNERS).

## License

MIT. See [LICENSE](LICENSE).
