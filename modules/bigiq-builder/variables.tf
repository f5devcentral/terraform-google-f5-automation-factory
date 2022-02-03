variable "prefix" {
  type = string
  validation {
    condition     = can(regex("^[a-z](?:[a-z0-9-]{4,61}[a-z0-9])$", var.prefix))
    error_message = "The prefix variable must be RFC1035 compliant and between 5 and 63 characters in length."
  }
  default     = "f5-automation-factory"
  description = <<-EOD
A prefix to apply to resource names to avoid collisions.
EOD
}

variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<-EOD
The GCP project id that will be used to launch an F5 BIG-IQ compute image builder.
EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<-EOD
An optional set of key:value string pairs to assign as labels to resources, in
addition to those enforced by the module.
EOD
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = <<-EOD
The machine type to use for BIG-IQ image builder.
EOD
}

variable "builder_subnetwork" {
  type        = string
  description = <<-EOD
The fully-qualified subnetwork self-link to use with the VM Builder for BIG-IQ.
EOD
}

variable "builder_sa" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]@(?:[a-z][a-z0-9-]{4,28}[a-z0-9].iam|appspot|cloudbuild|developer).gserviceaccount.com$", var.builder_sa))
    error_message = "The builder_sa value must be a valid service account email."
  }
  description = <<-EOD
The service account email that the builder VM will use.
EOD
}

variable "target_size_gb" {
  type = number
  validation {
    condition     = var.target_size_gb >= 120 && floor(var.target_size_gb) == var.target_size_gb
    error_message = "The target_size_gb value must be an integer >= 120."
  }
  default     = 120
  description = <<-EOD
The size of the target disk for BIG-IQ; default is 120.
EOD
}

variable "source_files" {
  type = list(string)
  validation {
    condition     = length(var.source_files) > 0 && length(join("", [for source in var.source_files : can(regex("^gs://[^/]+/", source)) ? "x" : ""])) == length(var.source_files)
    error_message = "At least one source_file must be provided, and all must be in form gs://bucket/path."
  }
  description = <<-EOD
The list of GCS source files to drive BIG-IG image creation.
EOD
}

variable "image_name" {
  type        = string
  default     = null
  description = <<-EOD
An optional image name to give to the generated BIG-IQ image.
EOD
}

variable "family_name" {
  type        = string
  default     = null
  description = <<-EOD
An optional family name to give to the generated BIG-IQ image.
EOD
}
