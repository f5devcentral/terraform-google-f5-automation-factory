output "bucket" {
  value       = module.automation_factory.bucket
  description = <<-EOD
The GCS bucket that will host automation factory artefacts.
EOD
}

output "source_repositories" {
  value       = module.automation_factory.source_repositories
  description = <<-EOD
A map of Google Source Repository names to self-links and URLs, that are managed
y this module.
EOD
}

output "artefact_repositories" {
  value       = module.automation_factory.artefact_repositories
  description = <<EOD
A map of Artifact Registry repositories names to self-links and URLs created by \
this automation factory.
EOD
}

output "vm_builder_sa" {
  value       = module.automation_factory.vm_builder_sa
  description = <<EOD
The fully-qualified email address of the VM Builder service account.
EOD
}
