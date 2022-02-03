output "bucket" {
  value       = google_storage_bucket.artefact_bucket.name
  description = <<-EOD
The GCS bucket that will host automation factory artefacts.
EOD
}

output "source_repositories" {
  value = { for repo in google_sourcerepo_repository.source_repos : repo.name => {
    self_link = repo.self_link
    url       = repo.url
  } }
  description = <<-EOD
A map of Google Source Repository names to self-links and URLs, that are managed
y this module.
EOD
}

output "artefact_repositories" {
  value = merge(
    { for repo in google_artifact_registry_repository.ar_repos : repo.repository_id => {
      # Docker repo declaration is a bare name
      repo_declaration = format("%s-docker.pkg.dev/%s/%s", repo.location, repo.project, repo.repository_id)
      id               = repo.id
      dependencies = {
        signing_key_urls = []
        repos            = {}
        packages         = []
      }
    } if repo.format == "DOCKER" },
    { for repo in google_artifact_registry_repository.ar_repos : repo.repository_id => {
      # Debian repo URL contains the Artefact Registry transport prefix
      repo_declaration = format("deb ar+https://%s-apt.pkg.dev/projects/%s %s main", repo.location, repo.project, repo.repository_id)
      id               = repo.id
      dependencies = {
        signing_key_urls = [
          format("https://%s-apt.pkg.dev/doc/repo-signing-key.gpg", repo.location),
          "https://packages.cloud.google.com/apt/doc/apt-key.gpg",
        ]
        repos = {
          ar_transport = "deb http://packages.cloud.google.com/apt apt-transport-artifact-registry-stable main"
        }
        packages = [
          "apt-transport-artifact-registry",
        ]
      }
    } if repo.format == "APT" },
    { for repo in google_artifact_registry_repository.ar_repos : repo.repository_id => {
      # RPM repo declaration is a stanza
      repo_declaration = <<-EOD
[${repo.name}]
name=${repo.description}
baseurl=https://${repo.location}-yum.pkg.dev/projects/${repo.project}/${repo.repository_id}
enabled=1
gpgcheck=0
repo_gpgcheck=1
EOD
      id               = repo.id
      dependencies = {
        signing_key_urls = [
          "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg",
        ]
        repos = {
          ar_transport = <<-EOD
[ar_transport]
name=Artifact Registry Plugin
baseurl=https://packages.cloud.google.com/yum/repos/dnf-plugin-artifact-registry-stable
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
EOD
        }
        packages = [
          "dnf-plugin-artifact-registry"
        ]
      }
    } if repo.format == "YUM" },
  )
  description = <<EOD
A map of Artifact Registry repositories names to self-links and URLs created by \
this automation factory, and any dependencies that must be installed in a GCP VM
in order to use the private repos.

NOTE 1: The RPM repo dependencies assume use of `dnf` for package management;
replace 'dnf' with 'yum' if appropriate.
NOTE 2: Some dependencies may already be installed depending on the OS and version
used.
EOD
}

output "vm_builder_sa" {
  value       = module.vmbuilder_sa.emails_list[0]
  description = <<EOD
The fully-qualified email address of the VM Builder service account.
EOD
}
