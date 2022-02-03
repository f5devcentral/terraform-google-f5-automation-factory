

# Get a reference to the project for its number, as used in the Cloud Builder
# service account
data "google_project" "default" {
  project_id = var.project_id
}

locals {
  # Add the VM builder service account to the set of admins
  admins = toset(concat([local.vmbuilder_sa_iam_id], var.admin_accounts))
  # This module needs to reference the fully-qualified IAM-prefixed id for the Cloud Build account
  cb_sa_iam = format("serviceAccount:%s@cloudbuild.gserviceaccount.com", data.google_project.default.number)
}

# Allow the Cloud Builder service account to be a storage admin on the artefact
# bucket
#
# NOTE: this does not change associations of other members
resource "google_storage_bucket_iam_member" "artefact_bucket_admin" {
  bucket = google_storage_bucket.artefact_bucket.name
  role   = "roles/storage.admin"
  member = local.cb_sa_iam
}

# Allow Cloud Builder to be a compute admin on the project to create images and
# launch VMs
resource "google_project_iam_member" "cb_compute_admin" {
  for_each = toset(var.cloud_build_project_roles)
  project  = var.project_id
  role     = each.value
  member   = local.cb_sa_iam

  depends_on = [google_project_service.apis]
}

# Allow these accounts to manage Cloud Builder
resource "google_project_iam_member" "cb_editors" {
  for_each = toset(var.admin_accounts)
  project  = var.project_id
  role     = "roles/cloudbuild.builds.editor"
  member   = each.value

  depends_on = [google_project_service.apis]
}

# Generate a set of service accounts from the email identifier list provided
data "google_service_account" "cb_sa_impersonate" {
  for_each   = toset(concat([local.vmbuilder_sa_email], var.impersonate_sa_emails))
  account_id = regex("^(.*)@", each.value)[0]
  project    = regex("@(.*)\\.iam\\.gserviceaccount\\.com$", each.value)[0]
}

# Allow the Cloud Builder service account to impersonate each service account
resource "google_service_account_iam_member" "cb_sa_impersonate" {
  for_each           = data.google_service_account.cb_sa_impersonate
  service_account_id = each.value.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.cb_sa_iam

  depends_on = [google_project_service.apis]
}

# Allow the Cloud Builder service account to have full access to specified bucket(s)
resource "google_storage_bucket_iam_member" "cb_admin_buckets" {
  for_each = toset(var.cloud_build_additional_buckets)
  bucket   = each.value
  role     = "roles/storage.admin"
  member   = local.cb_sa_iam

  depends_on = [google_project_service.apis]
}

# Allow these accounts to be admins on the contents of the artefacts bucket,
# along with VM builder service account
#
# NOTE: this does not change associations of other members
resource "google_storage_bucket_iam_member" "artefact_admins" {
  for_each = local.admins
  bucket   = google_storage_bucket.artefact_bucket.name
  role     = "roles/storage.objectAdmin"
  member   = each.value
}

# Assign source repo admin privileges to VM builder service account and any other
# provided accounts.
#
# NOTE: this does not change associations of other members
resource "google_sourcerepo_repository_iam_member" "source_repos_iam" {
  for_each = { for pair in setproduct([for k, v in google_sourcerepo_repository.source_repos : k], local.admins) : join("", pair) => {
    project = google_sourcerepo_repository.source_repos[pair[0]].project
    repo    = google_sourcerepo_repository.source_repos[pair[0]].repository
    member  = pair[1]
  } }
  project    = each.value.project
  repository = each.value.repository
  role       = "roles/source.admin"
  member     = each.value.member

  depends_on = [
    google_sourcerepo_repository.source_repos,
    module.vmbuilder_sa,
  ]
}

# Assign artifact registry admin privileges
#
# NOTE: this does not change associations of other members
resource "google_artifact_registry_repository_iam_member" "ar_repos_iam" {
  for_each = { for pair in setproduct([for k, v in google_artifact_registry_repository.ar_repos : k], local.admins) : join("", pair) => {
    project  = google_artifact_registry_repository.ar_repos[pair[0]].project
    name     = google_artifact_registry_repository.ar_repos[pair[0]].name
    location = google_artifact_registry_repository.ar_repos[pair[0]].location
    member   = pair[1]
  } }
  provider   = google-beta
  project    = each.value.project
  repository = each.value.name
  location   = each.value.location
  role       = "roles/artifactregistry.repoAdmin"
  member     = each.value.member

  depends_on = [
    google_sourcerepo_repository.source_repos,
    module.vmbuilder_sa,
  ]
}
