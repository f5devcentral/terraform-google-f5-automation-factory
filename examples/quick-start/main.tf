terraform {
  required_version = ">= 0.14.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.8.0"
    }
  }
  # Uncomment and configre the GCS bucket to use for Terraform state
  # backend "gcs" {
  #   bucket = "my-terraform-state-bucket"
  #   prefix = "automation-factory/quick-start"
  # }
}

# Use service account impersonation if a service account email has been provided
provider "google" {
  impersonate_service_account = var.tf_service_account
}

provider "google-beta" {
  impersonate_service_account = var.tf_service_account
}

module "automation_factory" {
  # TODO @memes
  # source         = "github.com/f5devcentral/terraform-google-f5-automation-factory?ref=v1.0.0"
  source     = "../../"
  prefix     = var.prefix
  project_id = var.project_id
  labels     = var.labels
}
