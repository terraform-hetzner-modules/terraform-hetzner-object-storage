# Upgrade guide

Before the first release, replace this template guidance with the module's actual
engine/provider requirements, compatibility decisions, and migration instructions.
The starting test matrix covers Terraform 1.7.5/1.16.6 and OpenTofu 1.8.8/1.13.1.
These are module compatibility targets; confirm that the selected providers support them.

## Before upgrading

Back up the consuming root configuration's state and commit its dependency lock file.
Update the module version and run `terraform init -upgrade` (or `tofu init -upgrade`).
Review the plan before applying it. Child module lock files do not constrain the consuming root configuration.

Document changes to minimum engine/provider versions, input types and defaults, outputs,
resource addresses, and map keys. Use a major release for incompatible changes.
Provide `moved` blocks or explicit migration instructions when resource addresses change.
Unknown object properties may be discarded by Terraform's object conversion; verify property
names against the generated input documentation.

Explain which changes can replace resources and how users should handle them.
Preserve existing resource names and caller-supplied map keys where possible.

## Checks

Run `terraform init -backend=false`, `terraform validate`, and `terraform test`,
or the equivalent `tofu` commands. Initialize and validate examples, child modules,
and test helpers separately. CI discovers these directories from tracked Terraform files.

Native tests belong in `tests/*.tftest.hcl`; shared setup belongs in `tests/setup/main.tf`.
Mock cloud providers to avoid creating infrastructure. Real local providers may be used to
check rendering and transformations without cloud credentials.

Before a production release, exercise creation, a second no-change plan, updates, and teardown
in a disposable account or project. Mocks do not verify live API behavior, quotas, or capacity.

## Provider coverage maintenance

With the module initialized, run `formr schema . -o docs/SCHEMA.md` to generate the
coverage report, then `formr check . --report docs/SCHEMA.md` to check for drift.
Use the same engine and provider selections recorded in the report's provenance.
No `SCHEMA.md` is included in this boilerplate; generate it for each implemented module.

Review provider-level settings and every resource/data-source property, including nested blocks,
computed attributes, and outputs. Make supported configurable properties accessible through the
module interface and document intentional omissions, fixed values, and Terraform lifecycle limitations.
Keep provider credentials in the caller's provider configuration.

The current default Formr policy checks inventory completeness and unresolved analysis.
Strict interface coverage and exception annotations are not yet implemented, so a passing default
check does not approve omitted fields. Review mappings and defaults alongside the generated report.

Regenerate README inputs and outputs with
`terraform-docs -c .github/linters/.terraform-docs.yml .`.

## Module changes

Replace this section for each release with concrete input/output changes, deprecations,
provider behavior changes, and migration examples. Include compatibility tests for behavior
that existing callers depend on.
