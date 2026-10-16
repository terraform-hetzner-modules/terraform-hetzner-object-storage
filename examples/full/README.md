# Full Object Storage example

Set `MINIO_USER` and `MINIO_PASSWORD` to Hetzner S3 credentials, then supply a globally unique
`name_prefix` with `TF_VAR_name_prefix`. `location` defaults to `fsn1`.
Run `terraform init`, review `terraform plan`, and apply when ready.
This example creates billable buckets. It uses no Terraform backend configuration.

Bucket names and URLs are exported for application configuration. The examples use
`force_destroy = false`; empty buckets yourself before teardown. The full example's archive
retention can prevent object deletion until each object's retention expires.
