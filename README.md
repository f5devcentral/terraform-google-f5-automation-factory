# F5 Automation Factory for Google Cloud

These Terraform modules can be used to establish an *automation factory* to
generate F5 product artefacts in your own GCP project.

## Overview

Customers often have to maintain their own deployment artefacts for F5 products
either to enforce consistent usage of approved versions, or because deployments
are not permitted to deploy artefacts from public repositories.

## Getting Started

The easiest way to begin is to use the [quick-start](examples/quick-start) example
as a base.

1. Clone the [quick-start](examples/quick-start) example

```shell
terraform init -from-module github.com/f5devcentral/terraform-google-f5-automation-factory/examples/quick-start
```

## Usage

The main root module enables required Google APIs, creates a VM builder service
account, and enables Cloud Build's service account to manage the building of
BIG-IP images, BIG-IQ images, NGINX+ images and containers.

Each [sub-module](modules) implements a specific automation factory use-case that
can be deployed independently as needed.

> NOTE: By default *all* F5 product sub-modules are enabled as part of the automation
> factory; you can selectively enable/disable aspects of the factory through the
> `features` variable.

<!-- markdownlint-disable no-inline-html no-bare-urls -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vmbuilder_sa"></a> [vmbuilder\_sa](#module\_vmbuilder\_sa) | terraform-google-modules/service-accounts/google | 4.1.0 |
| <a name="module_vmbuilder_vpc"></a> [vmbuilder\_vpc](#module\_vmbuilder\_vpc) | terraform-google-modules/network/google | 4.1.0 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_artifact_registry_repository.ar_repos](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_repository) | resource |
| [google-beta_google_artifact_registry_repository_iam_member.ar_repos_iam](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_repository_iam_member) | resource |
| [google_compute_firewall.iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_project_iam_member.cb_compute_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.cb_editors](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account_iam_member.cb_sa_impersonate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_sourcerepo_repository.source_repos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository) | resource |
| [google_sourcerepo_repository_iam_member.source_repos_iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sourcerepo_repository_iam_member) | resource |
| [google_storage_bucket.artefact_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.artefact_admins](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.artefact_bucket_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.cb_admin_buckets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_project.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_service_account.cb_sa_impersonate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The existing project id that will be used for an F5 automation factory. | `string` | n/a | yes |
| <a name="input_admin_accounts"></a> [admin\_accounts](#input\_admin\_accounts) | An optional list of IAM email identifiers that will be allowed to fully manage<br>Automation Factory resources through this module. Defaults to an empty list. | `list(string)` | `[]` | no |
| <a name="input_apis"></a> [apis](#input\_apis) | A list of GCP APIs to enable in the F5 automation factory project. | `list(string)` | <pre>[<br>  "compute.googleapis.com",<br>  "iap.googleapis.com",<br>  "oslogin.googleapis.com",<br>  "iam.googleapis.com",<br>  "secretmanager.googleapis.com",<br>  "storage-api.googleapis.com",<br>  "cloudbuild.googleapis.com",<br>  "sourcerepo.googleapis.com",<br>  "artifactregistry.googleapis.com",<br>  "containerscanning.googleapis.com"<br>]</pre> | no |
| <a name="input_apis_disable_on_destroy"></a> [apis\_disable\_on\_destroy](#input\_apis\_disable\_on\_destroy) | This value determines if the Google APIs enabled through this Terraform should<br>be disabled on Terraform destroy. Default value is 'false'. | `bool` | `false` | no |
| <a name="input_artefact_bucket"></a> [artefact\_bucket](#input\_artefact\_bucket) | Defines the parameters for the GCS bucket that will host Automation Factory<br>artefacts. If the name field is left blank (the default), a name will be generated<br>as 'prefix-project\_id', where `project_id` and `prefix` are the value of the<br>respective Terraform variables. GCS bucket names must be globally unique.<br><br>The location field specifies where the artefact bucket will be created; this<br>could be a GCE region, or a dual-region or multi-region specifier. Default is to create a<br>multi-region bucket in 'US'.<br><br>The force\_destroy defines the action taken on Terraform destroy; if set to true,<br>Terraform destroy will forcibly remove the aretefact bucket and all contents. If<br>left at the default value of 'false', Terraform destroy will fail to clean up<br>the bucket. | <pre>object({<br>    name          = string<br>    location      = string<br>    force_destroy = bool<br>    versioning    = bool<br>  })</pre> | <pre>{<br>  "force_destroy": false,<br>  "location": "US",<br>  "name": null,<br>  "versioning": true<br>}</pre> | no |
| <a name="input_artefact_registries"></a> [artefact\_registries](#input\_artefact\_registries) | n/a | <pre>object({<br>    container = object({<br>      name        = string<br>      description = string<br>      location    = string<br>      type        = string<br>    })<br>    deb = object({<br>      name        = string<br>      description = string<br>      location    = string<br>      type        = string<br>    })<br>    rpm = object({<br>      name        = string<br>      description = string<br>      location    = string<br>      type        = string<br>    })<br>  })</pre> | <pre>{<br>  "container": {<br>    "description": "OCI container registry for F5 Automation Factory",<br>    "location": "us",<br>    "name": null,<br>    "type": "DOCKER"<br>  },<br>  "deb": {<br>    "description": "deb package registry for F5 Automation Factory",<br>    "location": "us",<br>    "name": null,<br>    "type": "APT"<br>  },<br>  "rpm": {<br>    "description": "RPM package registry for F5 Automation Factory",<br>    "location": "us",<br>    "name": null,<br>    "type": "YUM"<br>  }<br>}</pre> | no |
| <a name="input_cloud_build_additional_buckets"></a> [cloud\_build\_additional\_buckets](#input\_cloud\_build\_additional\_buckets) | An optional list of additional buckets; the Cloud Builder service account will be<br>granted admin access to these buckets in addition to the artefact bucket created<br>by this module.<br><br>For example, if Cloud Build will be impersonating a Terraform service account<br>that is using a GCS bucket for state backend, Cloud Build will need to be able<br>to read and update that state.<br><br>E.g.<br>cloud\_build\_additional\_buckets = ["tf-state-bucket"] | `list(string)` | `[]` | no |
| <a name="input_cloud_build_project_roles"></a> [cloud\_build\_project\_roles](#input\_cloud\_build\_project\_roles) | n/a | `list(string)` | <pre>[<br>  "roles/compute.instanceAdmin.v1",<br>  "roles/iam.serviceAccountUser",<br>  "roles/iam.serviceAccountActor",<br>  "roles/compute.osLogin",<br>  "roles/iap.tunnelResourceAccessor"<br>]</pre> | no |
| <a name="input_impersonate_sa_emails"></a> [impersonate\_sa\_emails](#input\_impersonate\_sa\_emails) | An optional (but recommended) list of fully-qualified email addresses for<br>service accounts that Cloud Build will be allowed to impersonate. It is better<br>to create focused service accounts with a well-defined set of IAM roles, and allow<br>Cloud Build to impersonate those as needed, rather than granting additional roles<br>directly to Cloud Build.<br><br>E.g. to allow Cloud Build to impersonate a Terraform service account<br>impersonate\_sa\_emails = [<br>  "terraform@[PROJECT\_ID].iam.gserviceaccount.com"<br>] | `list(string)` | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional set of key:value string pairs to assign as labels to resources, in<br>addition to those enforced by the module. | `map(string)` | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix to apply to resource names; if deploying into a project shared with<br>others, you may need to set this value to avoid collisions with existing<br>deployments. Default value is 'f5-automation-factory'. | `string` | `"f5-automation-factory"` | no |
| <a name="input_source_repos"></a> [source\_repos](#input\_source\_repos) | An optional list of Google Source Repository names to be created and managed by<br>this module. Defaults to an empty list. | `list(string)` | `[]` | no |
| <a name="input_vmbuilders"></a> [vmbuilders](#input\_vmbuilders) | Defines the contexts for VM builders; a VPC subnetwork will be created in each<br>region. | <pre>object({<br>    vpc_cidr    = string<br>    subnet_size = number<br>    regions     = list(string)<br>  })</pre> | <pre>{<br>  "regions": [<br>    "us-west1",<br>    "us-central1",<br>    "us-east1"<br>  ],<br>  "subnet_size": 24,<br>  "vpc_cidr": "172.16.0.0/12"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artefact_repositories"></a> [artefact\_repositories](#output\_artefact\_repositories) | A map of Artifact Registry repositories names to self-links and URLs created by \<br>this automation factory, and any dependencies that must be installed in a GCP VM<br>in order to use the private repos.<br><br>NOTE 1: The RPM repo dependencies assume use of `dnf` for package management;<br>replace 'dnf' with 'yum' if appropriate.<br>NOTE 2: Some dependencies may already be installed depending on the OS and version<br>used. |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | The GCS bucket that will host automation factory artefacts. |
| <a name="output_source_repositories"></a> [source\_repositories](#output\_source\_repositories) | A map of Google Source Repository names to self-links and URLs, that are managed<br>y this module. |
| <a name="output_vm_builder_sa"></a> [vm\_builder\_sa](#output\_vm\_builder\_sa) | The fully-qualified email address of the VM Builder service account. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html no-bare-urls -->

## Development

Local development set up and contributing guidelines can be found in [CONTRIBUTING.md](CONTRIBUTING.md).

## Support

For support, please open a GitHub issue.  Note, the code in this repository is
community supported and is not supported by F5 Inc.  For a complete list of
supported projects please reference [SUPPORT.md](SUPPORT.md).

## Community Code of Conduct

Please refer to the [F5 DevCentral Community Code of Conduct](code_of_conduct.md).

## License

[Apache License 2.0](LICENSE)

## Copyright

Copyright 2022 F5, Inc.

### F5 Contributor License Agreement

Before you start contributing to any project sponsored by F5, Inc. (F5) on GitHub,
you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer
(if applicable) before signing the CLA since some employment agreements may have
restrictions on your contributions to other projects. Otherwise by submitting a
CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your
contributions, you represent that you have received permission to make contributions
on behalf of that employer, that your employer has waived such rights for your
contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally
entitled to grant the license recited therein. You represent further that each
employee of the entity that submits contributions is authorized to submit such
contributions on behalf of the entity pursuant to the CLA.
