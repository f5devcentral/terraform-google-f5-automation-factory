variable "tf_service_account" {
  type        = string
  default     = null
  description = <<-EOD
An optional service account email that the Google provider will be configured to
impersonate.
EOD
}

variable "prefix" {
  type        = string
  default     = "f5-automation-factory"
  description = <<EOD
A prefix to apply to resource names; if deploying into a project shared with
others, you may need to set this value to avoid collisions with existing
deployments. Default value is 'f5-automation-factory'.
EOD
}

variable "project_id" {
  type        = string
  description = <<EOD
The existing project id that will be used for an F5 automation factory.
EOD
}

variable "labels" {
  type = map(string)
  default = {
    example = "quick-start"
  }
  description = <<EOD
An optional set of key:value string pairs to assign as labels to resources, in
addition to those enforced by the module.
EOD
}
