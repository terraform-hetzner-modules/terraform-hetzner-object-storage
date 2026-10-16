terraform {
  required_version = ">= 1.7"
  required_providers {
    minio = { source = "aminueza/minio", version = "~> 3.45" }
  }
}
resource "terraform_data" "inputs" {
  input = {
    name   = "my-computed-bucket"
    policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = "*", Action = ["s3:GetObject"], Resource = ["arn:aws:s3:::my-computed-bucket/*"] }] })
  }
}
module "subject" {
  source = "../.."
  buckets = {
    computed = {
      name            = terraform_data.inputs.output.name
      policy          = { json = terraform_data.inputs.output.policy }
      lifecycle_rules = [{ id = "cleanup", expiration = { days = 30 } }]
    }
  }
}
output "keys" {
  description = "Stable bucket identities with computed names and policy contents."
  value       = keys(module.subject.names)
}
output "names" {
  description = "Resolved bucket names."
  value       = module.subject.names
}
