<p align="center">
    <!-- terraform-hetzner-object-storage -->
<img src="https://cdn.simpleicons.org/terraform/844FBA" alt="Terraform Logo" align="center" width="128">
<img src="https://avatars.githubusercontent.com/u/30047064?s=200&v=4" alt="Hetzner Logo" align="center" width="128">
    <h1 align="center">Hetzner Object Storage</h1>
    <h2 align="center"><code>object-storage</code></h2>
</p>

[![License](https://img.shields.io/github/license/terraform-hetzner-modules/terraform-hetzner-object-storage?label=License)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-_>=_1.7-brightgreen?logo=terraform&logoColor=623CE4)][terraform]
[![Opentofu](https://img.shields.io/badge/OpenTofu-_>=_1.8-brightgreen?logo=opentofu)][opentofu]
[![CI Status](https://github.com/terraform-hetzner-modules/terraform-hetzner-object-storage/actions/workflows/testing.yaml/badge.svg)](https://github.com/terraform-hetzner-modules/terraform-hetzner-object-storage/blob/main/.github/workflows/testing.yaml)
[![GitHub Release](https://img.shields.io/github/v/release/terraform-hetzner-modules/terraform-hetzner-object-storage?label=Release)][github_releases]
[![GitHub Activity](https://img.shields.io/github/commit-activity/m/terraform-hetzner-modules/terraform-hetzner-object-storage?label=Commits)][github_commits]
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovate&logoColor=1A1F6C)][renovate]
[![Pre-Commit](https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040)][pre-commit]

A [Terraform module][module] to manage multiple [Hetzner][hetzner] S3 buckets and their settings through
`aminueza/minio`. No MinIO server or AWS account is required.

## ✨ TL;DR

```hcl
module "storage" {
  source = "terraform-hetzner-modules/object-storage/hetzner"

  name_prefix = "my-company-observability-"
  defaults = {
    lifecycle_rules = [{
      id                                = "abort-incomplete-uploads"
      abort_incomplete_multipart_upload = { days_after_initiation = 7 }
    }]
  }
  buckets = {
    loki-chunks = {}
    tempo       = { name = "my-company-tempo-traces" }
  }
}
```

Configure the MinIO provider in the calling root as shown below. This Registry address becomes available
after the first release is published.

## Provider configuration

```hcl
terraform {
  required_providers {
    minio = { source = "aminueza/minio", version = "~> 3.45" }
  }
}

provider "minio" {
  minio_server        = "fsn1.your-objectstorage.com"
  minio_region        = "fsn1"
  minio_ssl           = true
  skip_bucket_tagging = true
  s3_compat_mode      = true
  # Credentials come from MINIO_USER and MINIO_PASSWORD.
}
```

Generate S3 credentials in the Hetzner Console, then supply the access key via `MINIO_USER` and the
secret key via `MINIO_PASSWORD` (or your root provider's `minio_user` and `minio_password` arguments).
These differ from `HCLOUD_TOKEN`. Provider configuration and credentials stay outside this module.
The provider name refers to its S3 client; no MinIO deployment is involved.
Follow [Hetzner's Terraform guide](https://docs.hetzner.com/storage/object-storage/getting-started/creating-a-bucket-minio-terraform/).

One provider configuration selects one project/credential pair and one regional endpoint (`fsn1`,
`nbg1`, or `hel1`). A single module call manages any number of buckets within those service limits.
For separate regions or projects, use aliased providers and separate calls; Terraform cannot select
provider configurations dynamically per map entry. Buckets must have globally unique names.

## Collections and shared defaults

`buckets` is a map keyed by stable identifiers, like our DNS module's `records` map. Empty maps create
nothing. Resource addresses use these keys, not bucket names. Optional `name` overrides the derived
`name_prefix + key`; `bucket_prefix` instead asks the provider to generate a unique suffix.
`name` and `bucket_prefix` are mutually exclusive. Names are not silently normalized.

`defaults` supplies bucket settings. Each non-null per-bucket field overrides its shared counterpart.
Explicit `false`, zero (where valid), and empty lists are preserved. Nested objects and lists replace
shared values as a whole; they are not recursively merged. Set `cors_rules = []` or
`lifecycle_rules = []` to remove inherited rules. For `versioning`, `policy`, or `retention`, use
`{ enabled = false }` to opt out of an inherited configuration. A null field inherits its default.
The built-in defaults are private access, `force_destroy = false`, no object locking, and no optional
configuration resources. `versioning = {}` enables versioning using its standard status.

Map keys, configuration presence/enabled flags, and rule counts must be known during planning.
Bucket names, rule values, and policy JSON can come from other resources. Policy documents are not
credentials; keep resource keys and the bucket collection non-sensitive.

## Bucket settings

| Input | Behavior |
| ----- | -------- |
| `acl` | `private` (default) or `public-read`; public access generates an object-read bucket policy. |
| `force_destroy` | Opt-in deletion of objects when removing a bucket. Defaults to false. |
| `object_locking` | Enable object locking at bucket creation. |
| `versioning` | `Enabled` or `Suspended`, with optional operation timeouts. |
| `policy` | Full JSON policy via `jsonencode(...)` or `file(...)`, with optional operation timeouts. |
| `retention` | Default `GOVERNANCE` or `COMPLIANCE` retention, using exactly one of `days` or `years`. Requires object locking. |
| `cors_rules` | CORS origins, methods, headers, exposed headers, IDs, and cache duration. |
| `lifecycle_rules` | Current/noncurrent expiration, expired delete markers, multipart cleanup, and filters. |

The MinIO provider implements its bucket `acl` argument by writing S3 policies. This module fixes
that argument to `private` as the bucket's creation baseline and manages subsequent public/custom
policies through `minio_s3_bucket_policy`. Public access and custom policies cannot be combined as
separate settings; put all permissions into the custom document instead. Returning to `private` or
disabling a custom policy removes that policy. Default private buckets without a managed policy do
not reconcile policies added outside Terraform.

Use the eventual bucket name when composing policy ARNs (`arn:aws:s3:::<bucket-name>/*`). Do not refer
back to this module's outputs inside its own inputs. In particular, a generated `bucket_prefix` name
cannot be interpolated into a custom policy in the same call; use an exact name for custom policies
that name the bucket. The generated `public-read` policy supports either naming mode.

Hetzner's project credentials can access all buckets in their project by default. A private bucket
is not an isolation boundary between those keys. For per-key restrictions, configure bucket policies
using [Hetzner's documented principals and examples](https://docs.hetzner.com/storage/object-storage/faq/s3-credentials/).

The `names`, `ids`, `arns`, `urls`, and complete `buckets` outputs are keyed by the same caller
identifiers. `urls` contains the provider-reported path-style bucket URLs, not hostnames.
The complete provider attributes include the fixed private ACL baseline even when a separate policy
grants public access. Outputs depend on completion of all managed settings so consumers can wait for configured
buckets. For example, use `module.storage.names.tempo` in Tempo's storage configuration.
For Loki/Tempo, start with private buckets and multipart cleanup; keep application retention owned by
the application's compactor unless bucket expiration is deliberately coordinated with it.

## Lifecycle and imports

Removing an entry or setting `create = false` plans destruction. Nonempty buckets block destruction
unless `force_destroy` was enabled before removal. Retention may still prevent deletion; enabling
force destruction does not bypass compliance retention. Bucket names identify storage: changing an
exact name replaces the bucket and does not migrate its objects. Provider-generated prefixes are
create-only; changing an existing prefix may not rename or replace the bucket.

Object locking must be selected when the bucket is created and cannot subsequently be disabled.
The provider does not force replacement for changes to this setting; do not treat toggling it as a
migration procedure. Locking enables versioning automatically. Removing a managed versioning resource
attempts to suspend versioning (which locked buckets may reject); it does not delete existing versions.
Removing CORS, lifecycle, or retention configuration removes that bucket configuration, not existing
objects or their individual retention locks.

Import existing buckets by name into the appropriate key:

```hcl
import {
  to = module.storage.minio_s3_bucket.current["tempo"]
  id = "my-company-tempo-traces"
}
```

Import each configured existing child resource separately using the same bucket name, for example
`module.storage.minio_s3_bucket_versioning.current["tempo"]` or
`module.storage.minio_s3_bucket_policy.current["tempo"]`. The provider also supports bucket-name imports
for CORS, lifecycle, and object lock configuration. Import the matching configuration before applying;
otherwise the bucket's private creation baseline can overwrite an existing policy.

## Compatibility and examples

Requires Terraform >= 1.7 (OpenTofu >= 1.8 tested) and `aminueza/minio ~> 3.45`.
See [basic](examples/basic) for application buckets and [full](examples/full) for shared defaults,
per-bucket overrides, policies, versioning, CORS, lifecycle, and retention.
The module does not create credentials, upload application objects, or configure a Terraform backend.

Unsupported backend features are intentionally excluded: MinIO admin quotas, bucket tags, replication,
storage-class transitions, newer-noncurrent-version counts, and MinIO-specific versioning exclusions.
See [Hetzner's supported actions](https://docs.hetzner.com/storage/object-storage/supported-actions/) and
the [schema report](docs/SCHEMA.md). Report completeness does not imply live API compatibility.
Run `terraform init -backend=false`, `terraform validate`, and `terraform test` for credential-free,
mocked tests. Live creation/update/import/no-change-plan/teardown remains a separate acceptance step.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_minio"></a> [minio](#provider\_minio) | ~> 3.45 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | Buckets keyed by stable identifiers known at plan time. Names default to name\_prefix plus the key. Set name for an exact name, or bucket\_prefix for a provider-generated suffix. Optional configuration presence/enabled flags and rule counts must be known at plan time; names and policy JSON may be computed. | ```map(object({ name = optional(string) bucket_prefix = optional(string) acl = optional(string) force_destroy = optional(bool) object_locking = optional(bool) versioning = optional(object({ enabled = optional(bool, true) status = optional(string, "Enabled") timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) policy = optional(object({ enabled = optional(bool, true) json = optional(string) timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) retention = optional(object({ enabled = optional(bool, true) mode = optional(string, "GOVERNANCE") days = optional(number) years = optional(number) })) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) }))) lifecycle_rules = optional(list(object({ id = string status = optional(string, "Enabled") filter = optional(object({ prefix = optional(string) object_size_greater_than = optional(number) object_size_less_than = optional(number) tag = optional(object({ key = string, value = string })) and = optional(object({ prefix = optional(string) tags = optional(map(string)) object_size_greater_than = optional(number) object_size_less_than = optional(number) })) })) expiration = optional(object({ days = optional(number) date = optional(string) expired_object_delete_marker = optional(bool) })) noncurrent_version_expiration = optional(object({ noncurrent_days = number })) abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number })) }))) }))``` | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage the configured buckets and their settings. Setting false plans removal of existing resources. | `bool` | `true` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Shared bucket settings. Non-null per-bucket fields override these. Nested objects and lists are replaced as a whole; empty lists clear inherited rules, and enabled=false disables an inherited optional configuration. | ```object({ acl = optional(string, "private") force_destroy = optional(bool, false) object_locking = optional(bool, false) versioning = optional(object({ enabled = optional(bool, true) status = optional(string, "Enabled") timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) policy = optional(object({ enabled = optional(bool, true) json = optional(string) timeouts = optional(object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })) })) retention = optional(object({ enabled = optional(bool, true) mode = optional(string, "GOVERNANCE") days = optional(number) years = optional(number) })) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) })), []) lifecycle_rules = optional(list(object({ id = string status = optional(string, "Enabled") filter = optional(object({ prefix = optional(string) object_size_greater_than = optional(number) object_size_less_than = optional(number) tag = optional(object({ key = string, value = string })) and = optional(object({ prefix = optional(string) tags = optional(map(string)) object_size_greater_than = optional(number) object_size_less_than = optional(number) })) })) expiration = optional(object({ days = optional(number) date = optional(string) expired_object_delete_marker = optional(bool) })) noncurrent_version_expiration = optional(object({ noncurrent_days = number })) abort_incomplete_multipart_upload = optional(object({ days_after_initiation = number })) })), []) })``` | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Literal prefix for names derived from map keys. Exact names and bucket\_prefix override it; no random suffix is added. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arns"></a> [arns](#output\_arns) | Bucket ARNs for policy statements indexed by stable caller keys. |
| <a name="output_buckets"></a> [buckets](#output\_buckets) | Complete bucket attributes indexed by stable caller keys, after all managed bucket settings are applied. |
| <a name="output_ids"></a> [ids](#output\_ids) | Bucket IDs indexed by stable caller keys. |
| <a name="output_names"></a> [names](#output\_names) | Bucket names indexed by stable caller keys. |
| <a name="output_urls"></a> [urls](#output\_urls) | Provider-reported bucket URLs indexed by stable caller keys. |
<!-- END_TF_DOCS -->

### 🔃 Contributing

Refer to our [documentation for contributors][contributing] for contributing guidelines, commit message
formats and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Terraform Hetzner Modules][org]. Refer to the [`AUTHORS`][authors] or [`CODEOWNERS`][owners]
for more information. You may also use the linked contact details to reach out directly.

### ©️ Copyright

- _Assets provided by:_ **[HashiCorp][hashicorp]**
- _Sources provided by:_ **[Terraform Hetzner Modules][org]** under the **[MIT License][license]**

<!-- INTERNAL REFERENCES -->

<!-- Project references -->

<!-- File references -->

[license]: LICENSE
[contributing]: docs/CONTRIBUTING.md
[authors]: .github/AUTHORS
[owners]: .github/CODEOWNERS

<!-- General links -->

[org]: https://github.com/terraform-hetzner-modules
[terraform]: https://terraform.io
[opentofu]: https://opentofu.org/
[hashicorp]: https://www.hashicorp.com/
[hetzner]: https://hetzner.com
[github_releases]: https://github.com/terraform-hetzner-modules/terraform-hetzner-object-storage/releases
[github_commits]: https://github.com/terraform-hetzner-modules/terraform-hetzner-object-storage/commits/main/

<!-- Third-party -->

[module]: https://registry.terraform.io/modules/terraform-hetzner-modules/object-storage/hetzner/latest
[renovate]: https://renovatebot.com/
[pre-commit]: https://pre-commit.com/
