provider "minio" {
  minio_server        = "${var.location}.your-objectstorage.com"
  minio_region        = var.location
  minio_ssl           = true
  skip_bucket_tagging = true
  s3_compat_mode      = true
  # Set MINIO_USER and MINIO_PASSWORD outside Terraform configuration.
}
