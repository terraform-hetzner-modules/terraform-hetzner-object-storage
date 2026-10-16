<p align="center">
    <!-- terraform-PROVIDER-MODULE -->
    <img src="https://cdn.simpleicons.org/terraform/844FBA" alt="Terraform Logo" align="center" width="128">
    <h1 align="center">Terraform &lt;Provider&gt; Modules</h1>
    <h2 align="center"><code>MODULE</code></h2>
</p>

[![License](https://img.shields.io/github/license/ORG/terraform-PROVIDER-MODULE?label=License)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-_>=_1.7-brightgreen?logo=terraform&logoColor=623CE4)][terraform]
[![OpenTofu](https://img.shields.io/badge/OpenTofu-_>=_1.8-brightgreen?logo=opentofu)][opentofu]
[![CI Status](https://github.com/ORG/terraform-PROVIDER-MODULE/actions/workflows/testing.yaml/badge.svg)](https://github.com/ORG/terraform-PROVIDER-MODULE/actions/workflows/testing.yaml)
[![GitHub Release](https://img.shields.io/github/v/release/ORG/terraform-PROVIDER-MODULE?label=Release)][github_releases]
[![GitHub Activity](https://img.shields.io/github/commit-activity/m/ORG/terraform-PROVIDER-MODULE?label=Commits)][github_commits]
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovate&logoColor=1A1F6C)][renovate]
[![Pre-Commit](https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040)][pre-commit]

A [Terraform module][module] to manage MODULE resources with the selected provider.
Replace this sentence with the module's purpose when creating a repository from this template.

## ✨ TL;DR

```hcl
module "example" {
  source = "ORG/MODULE/PROVIDER"

  # Configure the module's required inputs here.
}
```

## Initialize this template

Replace these placeholders throughout the repository before publishing a module:

| Placeholder | Meaning |
| ----------- | ------- |
| `ORG` | GitHub organization and Terraform Registry namespace; adjust separately if they differ. |
| `PROVIDER` | Provider slug used in repository names and Registry module addresses. |
| `<Provider>` / `&lt;Provider&gt;` | Human-readable provider name in Terraform &lt;Provider&gt; Modules. |
| `MODULE` | Module name used in the repository, Registry address, and README. |
| `OWNER` | GitHub user or `ORG/TEAM` in `.github/CODEOWNERS`. |
| `OWNER_NAME`, `OWNER_EMAIL` | Maintainer name and contact address in `.github/AUTHORS`. |

Add `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf` for the root module.
Declare `required_version` and each provider's source and version constraint in `versions.tf`.
Provider configurations and credentials belong in the consuming root configuration.
Add a provider logo if desired; the template includes only the shared Terraform logo.

Put runnable examples in `examples/` and optional child modules in `modules/`.
Keep native tests in `tests/*.tftest.hcl` and shared setup configuration in `tests/setup/main.tf`.
The Testing workflow discovers tracked `.tf` and `.tf.json` directories, so add new files to Git before
running its discovery commands locally. No module-specific paths need to be changed.

This template deliberately contains no resource implementation or test cases. A green run of the
empty template verifies its tooling; add assertions for the module's actual behavior before release.
Remove this initialization section once the module is configured.

## Compatibility and examples

The starting CI matrix covers Terraform 1.7.5/1.16.6 and OpenTofu 1.8.8/1.13.1.
Set and document the module's actual engine and provider requirements, and adjust the matrix and badges
if the chosen provider needs newer versions. Provider compatibility must be checked for each module.

Document the examples and provider credential environment variables here once they exist.
Use mocked providers for cloud resources in native tests; tests that use real local providers must
remain credential-free. Live integration tests should run separately in a disposable account or project.

Run `terraform init -backend=false`, `terraform validate`, and `terraform test`
for local validation, or use the equivalent `tofu` commands.
See the [upgrade guide](docs/UPGRADING.md) for release and compatibility checks.

After adding and initializing the module, generate provider coverage with
`formr schema . -o docs/SCHEMA.md` and check it with
`formr check . --report docs/SCHEMA.md`. Add a link to the generated report here.
The boilerplate does not ship a schema report because it has no provider or resource declarations.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->

### 🔃 Contributing

Refer to our [documentation for contributors][contributing] for development checks, native tests,
commit message formats, and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Terraform &lt;Provider&gt; Modules][org].
Refer to the [`AUTHORS`][authors] or [`CODEOWNERS`][owners] for more information.
You may also use the linked contact details to reach out directly.

### ©️ Copyright

- _Assets provided by:_ **[HashiCorp][hashicorp]**
- _Sources provided by:_ **[Terraform &lt;Provider&gt; Modules][org]** under the **[MIT License][license]**

<!-- File references -->

[license]: LICENSE
[contributing]: docs/CONTRIBUTING.md
[authors]: .github/AUTHORS
[owners]: .github/CODEOWNERS

<!-- General links -->

[org]: https://github.com/ORG
[terraform]: https://terraform.io
[opentofu]: https://opentofu.org/
[hashicorp]: https://www.hashicorp.com/
[github_releases]: https://github.com/ORG/terraform-PROVIDER-MODULE/releases
[github_commits]: https://github.com/ORG/terraform-PROVIDER-MODULE/commits/main/

<!-- Third-party -->

[module]: https://registry.terraform.io/modules/ORG/MODULE/PROVIDER/latest
[renovate]: https://renovatebot.com/
[pre-commit]: https://pre-commit.com/
