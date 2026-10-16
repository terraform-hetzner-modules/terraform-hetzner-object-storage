# Basic Object Storage example

Creates two private buckets for documents and uploads using a shared naming prefix. No versioning,
CORS, policy, lifecycle, or retention configuration is enabled.

## Usage

Set `MINIO_USER` and `MINIO_PASSWORD` to Hetzner S3 credentials. Set `TF_VAR_name_prefix` to a unique
lowercase prefix including its trailing hyphen, such as `my-company-demo-`. `location` defaults to `fsn1`.

```shell
terraform init
terraform plan
terraform apply
```

Bucket names and URLs are exported by caller key. Buckets use `force_destroy = false`; empty them
before teardown. See the [full example](../full) for every available setting.
