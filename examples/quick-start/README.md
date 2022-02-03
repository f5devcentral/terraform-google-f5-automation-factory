# Private Bastion Terraform module for Google Cloud

This module implements a wrapper around Google's published bastion module that
allows it to function correctly when deployed in a private VPC without public
internet access.

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
| <a name="module_automation_factory"></a> [automation\_factory](#module\_automation\_factory) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The existing project id that will be used for an F5 automation factory. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional set of key:value string pairs to assign as labels to resources, in<br>addition to those enforced by the module. | `map(string)` | <pre>{<br>  "example": "quick-start"<br>}</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix to apply to resource names; if deploying into a project shared with<br>others, you may need to set this value to avoid collisions with existing<br>deployments. Default value is 'f5-automation-factory'. | `string` | `"f5-automation-factory"` | no |
| <a name="input_tf_service_account"></a> [tf\_service\_account](#input\_tf\_service\_account) | An optional service account email that the Google provider will be configured to<br>impersonate. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artefact_repositories"></a> [artefact\_repositories](#output\_artefact\_repositories) | A map of Artifact Registry repositories names to self-links and URLs created by \<br>this automation factory. |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | The GCS bucket that will host automation factory artefacts. |
| <a name="output_source_repositories"></a> [source\_repositories](#output\_source\_repositories) | A map of Google Source Repository names to self-links and URLs, that are managed<br>y this module. |
| <a name="output_vm_builder_sa"></a> [vm\_builder\_sa](#output\_vm\_builder\_sa) | The fully-qualified email address of the VM Builder service account. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html no-bare-urls -->
