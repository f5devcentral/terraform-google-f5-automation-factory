variable "prefix" {
  type = string
  validation {
    # This value drives multiple derivative resource names and id's; the maximum
    # length permitted is limited by service account to 30 chars, with -vm-builder
    # added by the module. So limit to 19 chars.
    condition     = can(regex("^[a-z](?:[a-z0-9-]{4,17}[a-z0-9])$", var.prefix))
    error_message = "The prefix variable must be RFC1035 compliant and between 5 and 19 characters in length."
  }
  default     = "f5-automation-factory"
  description = <<EOD
A prefix to apply to resource names; if deploying into a project shared with
others, you may need to set this value to avoid collisions with existing
deployments. Default value is 'f5-automation-factory'.
EOD
}

variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<EOD
The existing project id that will be used for an F5 automation factory.
EOD
}

variable "apis" {
  type = list(string)
  validation {
    condition     = length(join("", [for api in var.apis : can(regex("^[a-z-]+\\.googleapis\\.com$", api)) ? "x" : ""])) == length(var.apis)
    error_message = "Each api entry must be a valid googleapis.com value."
  }
  default = [
    "compute.googleapis.com",
    "iap.googleapis.com",
    "oslogin.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "storage-api.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "artifactregistry.googleapis.com",
    "containerscanning.googleapis.com",
  ]
  description = <<EOD
A list of GCP APIs to enable in the F5 automation factory project.
EOD
}

variable "apis_disable_on_destroy" {
  type        = bool
  default     = false
  description = <<EOD
This value determines if the Google APIs enabled through this Terraform should
be disabled on Terraform destroy. Default value is 'false'.
EOD
}

variable "cloud_build_project_roles" {
  type = list(string)
  validation {
    condition     = length(join("", [for role in var.cloud_build_project_roles : can(regex("^(?:organizations/[0-9]+/|projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/)?roles/.*$", role)) ? "x" : ""])) == length(var.cloud_build_project_roles)
    error_message = "Each cloud_build_project_roles entry must be a valid role name."
  }
  default = [
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountActor",
    "roles/compute.osLogin",
    "roles/iap.tunnelResourceAccessor",
  ]
}

variable "admin_accounts" {
  type = list(string)
  validation {
    condition     = length(join("", [for account in var.admin_accounts : can(regex("^(?:user|group|serviceAccount):.*@.*$", account)) ? "x" : ""])) == length(var.admin_accounts)
    error_message = "Each admin_accounts entry must be a valid IAM account identifier."
  }
  default     = []
  description = <<EOD
An optional list of IAM email identifiers that will be allowed to fully manage
Automation Factory resources through this module. Defaults to an empty list.
EOD
}

variable "impersonate_sa_emails" {
  type = list(string)
  validation {
    condition     = length(join("", [for account in var.impersonate_sa_emails : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]@(?:[a-z][a-z0-9-]{4,28}[a-z0-9].iam|appspot|cloudbuild|developer).gserviceaccount.com$", account)) ? "x" : ""])) == length(var.impersonate_sa_emails)
    error_message = "Each impersonate_sa_emails entry must be a valid service account email."
  }
  default     = []
  description = <<EOD
An optional (but recommended) list of fully-qualified email addresses for
service accounts that Cloud Build will be allowed to impersonate. It is better
to create focused service accounts with a well-defined set of IAM roles, and allow
Cloud Build to impersonate those as needed, rather than granting additional roles
directly to Cloud Build.

E.g. to allow Cloud Build to impersonate a Terraform service account
impersonate_sa_emails = [
  "terraform@[PROJECT_ID].iam.gserviceaccount.com"
]
EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<EOD
An optional set of key:value string pairs to assign as labels to resources, in
addition to those enforced by the module.
EOD
}

variable "artefact_bucket" {
  type = object({
    name          = string
    location      = string
    force_destroy = bool
    versioning    = bool
  })
  default = {
    name          = null
    location      = "US"
    force_destroy = false
    versioning    = true
  }
  description = <<-EOD
Defines the parameters for the GCS bucket that will host Automation Factory
artefacts. If the name field is left blank (the default), a name will be generated
as 'prefix-project_id', where `project_id` and `prefix` are the value of the
respective Terraform variables. GCS bucket names must be globally unique.

The location field specifies where the artefact bucket will be created; this
could be a GCE region, or a dual-region or multi-region specifier. Default is to create a
multi-region bucket in 'US'.

The force_destroy defines the action taken on Terraform destroy; if set to true,
Terraform destroy will forcibly remove the aretefact bucket and all contents. If
left at the default value of 'false', Terraform destroy will fail to clean up
the bucket.
EOD
}

variable "cloud_build_additional_buckets" {
  type        = list(string)
  default     = []
  description = <<EOD
An optional list of additional buckets; the Cloud Builder service account will be
granted admin access to these buckets in addition to the artefact bucket created
by this module.

For example, if Cloud Build will be impersonating a Terraform service account
that is using a GCS bucket for state backend, Cloud Build will need to be able
to read and update that state.

E.g.
cloud_build_additional_buckets = ["tf-state-bucket"]
EOD
}

variable "source_repos" {
  type        = list(string)
  default     = []
  description = <<EOD
An optional list of Google Source Repository names to be created and managed by
this module. Defaults to an empty list.
EOD
}

variable "artefact_registries" {
  type = object({
    container = object({
      name        = string
      description = string
      location    = string
      type        = string
    })
    deb = object({
      name        = string
      description = string
      location    = string
      type        = string
    })
    rpm = object({
      name        = string
      description = string
      location    = string
      type        = string
    })
  })
  default = {
    container = {
      name        = null
      description = "OCI container registry for F5 Automation Factory"
      location    = "us"
      type        = "DOCKER"
    }
    deb = {
      name        = null
      description = "deb package registry for F5 Automation Factory"
      location    = "us"
      type        = "APT"
    }
    rpm = {
      name        = null
      description = "RPM package registry for F5 Automation Factory"
      location    = "us"
      type        = "YUM"
    }
  }
}

variable "vmbuilders" {
  type = object({
    vpc_cidr    = string
    subnet_size = number
    regions     = list(string)
  })
  default = {
    vpc_cidr    = "172.16.0.0/12"
    subnet_size = 24
    regions     = ["us-west1", "us-central1", "us-east1"]
  }
  description = <<EOD
Defines the contexts for VM builders; a VPC subnetwork will be created in each
region.
EOD
}
