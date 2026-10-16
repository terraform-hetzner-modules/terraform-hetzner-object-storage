terraform {
  required_version = ">= 1.7"
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.45"
    }
  }
}
