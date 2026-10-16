# Maintenance and upgrade guide

The module requires Terraform >= 1.7 and `aminueza/minio ~> 3.45`.
CI covers Terraform 1.7.5/1.16.6 and OpenTofu 1.8.8/1.13.1.
Commit the consuming root's dependency lock file. Review provider changes and Hetzner S3 compatibility
before upgrading; provider schema support is not proof of backend support.

## Checks

Run `pre-commit run --all-files`, `terraform init -backend=false`, `terraform validate`, and
`terraform test`. Initialize/validate both examples and `tests/setup` separately. Native tests mock
MinIO and exercise map identity, defaults, optional configuration opt-outs, policy ownership,
computed values, and cross-resource validation. No live credentials are needed.

Generate coverage with `formr schema . -o docs/SCHEMA.md`, then run
`formr check . --report docs/SCHEMA.md`. Regenerate README tables with
`terraform-docs -c .github/linters/.terraform-docs.yml .`.
Provider arguments are caller-owned; computed IDs/ARNs/URLs are outputs. SDK resource `id` fields
are provider-managed/import identifiers rather than creation inputs.

## Deliberate schema restrictions

| Resource field | Reason |
| -------------- | ------ |
| `minio_s3_bucket.acl` | Fixed private creation baseline; public/custom access has a single policy resource owner. |
| `minio_s3_bucket.quota` | Uses the MinIO admin API, unavailable on Hetzner. |
| `minio_s3_bucket.tags` | Bucket tagging is unsupported by Hetzner; examples disable provider tagging operations. |
| Versioning `exclude_folders`, `excluded_prefixes` | MinIO-specific extensions to S3 versioning. |
| Lifecycle `transition`, `noncurrent_version_transition` | Hetzner does not expose storage-class transitions. |
| Lifecycle `newer_noncurrent_versions` | Hetzner only supports `NoncurrentDays` for noncurrent expiration. |
| Object lock `object_lock_enabled` | Always Enabled when default retention is managed; locking is a creation-time bucket choice. |

No credential/IAM/admin, encryption, replication, notification, quota, or redundant retention/anonymous
access resources are wrapped. Lifecycle filters still support object tags; this is distinct from
unsupported bucket tagging. Formr records omitted fields truthfully; its inventory check is not a
certificate of complete provider or backend coverage.

## Live acceptance

Use disposable buckets and review costs before testing. Check initial creation, a second no-change
plan, policy/public/private transitions, versioning, rule updates/removal, imports, and teardown.
Verify the configured region is used for both the endpoint and request signing.
Test nonempty-bucket deletion only with disposable objects and an explicit force_destroy opt-in.
Keep locking tests separate: retention can prevent teardown even with force destruction enabled.
Never use production Loki/Tempo buckets for destructive acceptance tests.

Changing exact bucket names replaces storage without migrating data. Preserve map keys to preserve
Terraform resource addresses. Object locking is irreversible and the provider does not replace a
bucket when its flag changes. Read the README before removing managed optional configurations.
The provider's bucket read does not reconcile out-of-band ACL policies; managed policy resources do.
