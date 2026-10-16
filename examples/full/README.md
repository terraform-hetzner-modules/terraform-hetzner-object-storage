# Full Object Storage example

This example explicitly configures every root-module input and nested field. It uses separate buckets
and rules for mutually exclusive settings, so the configuration can be planned as a whole.

| Bucket | Use case |
| ------ | -------- |
| `documents` | Derives its name from the map key and inherits every shared setting, including seven-day retention. |
| `archive` | Overrides every settings group, with an exact name, one-year retention, and custom operation timeouts. |
| `downloads` | Public object downloads, suspended versioning, and explicit opt-outs from inherited settings. |
| `temporary` | Provider-generated name, optional configuration disabled, and force deletion of disposable content. |

The `defaults` and `archive` blocks both show all settings fields. Their lifecycle rules separately
demonstrate prefix, tag, size, and combined filters; expiration by days/date/delete marker; noncurrent
expiration; multipart cleanup; and Enabled/Disabled statuses. The fixed-date rule is disabled so the
example does not acquire a new expiration cutoff merely because time passes.

`name` and `bucket_prefix`, retention `days` and `years`, and the expiration/filter alternatives
cannot all be enabled together. Nulls document the unused alternative; other buckets or rules provide
concrete examples of it. `enabled = false` and empty lists demonstrate clearing inherited settings.
Both policy and versioning show all four operation timeouts. Outputs expose all five module outputs.

## Usage

Set `MINIO_USER` and `MINIO_PASSWORD` to Hetzner S3 credentials. Supply a unique, lowercase naming prefix
including its trailing hyphen (for example `TF_VAR_name_prefix=my-company-demo-`). Keep the prefix at
most 33 characters so the provider can append its generated suffix. `location` defaults to `fsn1`.

```shell
terraform init
terraform plan
terraform apply
```

This creates four billable buckets, including one public-read bucket. Two buckets enable object
locking and default retention; that choice cannot later be disabled. Retention can prevent object
deletion until it expires. Only `temporary` enables force destruction. The shared policy targets the
`documents` bucket specifically; other buckets replace or disable it. Adjust policy resources if you
add more inheriting buckets.

CORS permits browser requests but does not grant access. Object-tag lifecycle filters differ from
unsupported bucket tagging. Lifecycle expiration and retention intentionally overlap: existing locks
continue to protect objects until their retention expires. For routine storage without those settings,
start with the [basic example](../basic).
