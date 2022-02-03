# This module has been updated to use Terraform 0.14
terraform {
  required_version = ">= 0.14.5"
  required_providers {
    google = ">= 4.8.0"
  }
}

locals {
  labels = merge({
    f5-package = "github-com-f5devcentral-terraform-google-f5-automation-factory"
  }, var.labels)
}

# Enable any GCP APIs needed for automation factory
resource "google_project_service" "apis" {
  for_each           = toset(var.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = var.apis_disable_on_destroy
}

# Create a GCS bucket for Cloud Builder automation factory artefacts
resource "google_storage_bucket" "artefact_bucket" {
  project  = var.project_id
  name     = coalesce(var.artefact_bucket.name, format("%s-%s", var.prefix, var.project_id))
  location = var.artefact_bucket.location
  versioning {
    enabled = var.artefact_bucket.versioning
  }
  force_destroy = var.artefact_bucket.force_destroy
  labels        = local.labels

  depends_on = [google_project_service.apis]
}

# Create any requested source repositories
resource "google_sourcerepo_repository" "source_repos" {
  for_each = toset(var.source_repos)
  project  = var.project_id
  name     = each.value

  depends_on = [google_project_service.apis]
}

# Create the automation factory repositories
resource "google_artifact_registry_repository" "ar_repos" {
  for_each = { for k, v in var.artefact_registries : k => {
    name        = coalesce(v.name, format("%s-%s", var.prefix, k))
    description = coalesce(v.description, format("%s repository (%s)", v.type, var.prefix))
    location    = v.location
    type        = v.type
  } }
  provider      = google-beta
  project       = var.project_id
  repository_id = each.value.name
  format        = each.value.type
  location      = each.value.location
  description   = each.value.description
  labels        = local.labels

  depends_on = [google_project_service.apis]
}
