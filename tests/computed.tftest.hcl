mock_provider "minio" {}
run "computed_inputs_plan" {
  command = plan
  module { source = "./tests/setup" }
  assert {
    condition     = output.keys == ["computed"]
    error_message = "Computed names and policy JSON must not affect resource addresses."
  }
}
run "computed_inputs_apply" {
  command = apply
  module { source = "./tests/setup" }
  assert {
    condition     = output.names.computed == "my-computed-bucket"
    error_message = "Computed names must propagate through the module."
  }
}
