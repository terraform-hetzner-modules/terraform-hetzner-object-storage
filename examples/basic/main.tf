module "storage" {
  source      = "../.."
  name_prefix = var.name_prefix
  buckets = {
    documents = {}
    uploads   = {}
  }
}
