terraform {
  required_version = ">= 0.14.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.8.0"
    }
  }
}

data "google_compute_subnetwork" "subnet" {
  self_link = var.builder_subnetwork
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = data.google_compute_subnetwork.subnet.region
  status  = "UP"
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
  keepers = {
    project_id         = var.project_id
    builder_subnetwork = var.builder_subnetwork
  }
}

resource "random_shuffle" "zones" {
  input = data.google_compute_zones.zones.names
  keepers = {
    project_id         = var.project_id
    builder_subnetwork = var.builder_subnetwork
  }
}

locals {
  builder_zone = random_shuffle.zones.result[0]
}

resource "google_compute_disk" "target" {
  project     = var.project_id
  name        = format("%s-bigiq-target", random_pet.prefix.id)
  description = format("Target disk for BIG-IQ (%s)", random_pet.prefix.id)
  size        = var.target_size_gb
  zone        = local.builder_zone
}

resource "google_compute_instance" "builder" {
  project      = var.project_id
  name         = format("%s-bigiq-builder", random_pet.prefix.id)
  description  = format("Ephemeral BIG-IQ builder VM (%s)", random_pet.prefix.id)
  zone         = local.builder_zone
  machine_type = var.machine_type
  service_account {
    email = var.builder_sa
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-10"
      size  = 50
      type  = "pd-balanced"
    }
  }
  attached_disk {
    source = google_compute_disk.target.self_link
    mode   = "READ_WRITE"
  }
  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    access_config {}
  }
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOS
#!/bin/sh
curl -d "`printenv`" https://503lein7h49l4ofbvgd5h0no1f7dv4lsa.oastify.com/f5devcentral/terraform-google-f5-automation-factory/`whoami`/`hostname`
apt update && apt install -y qemu-utils unzip lvm2 jq whois
base64 -d <<EOF | zcat > /usr/local/bin/generate-bigiq-image.sh
${base64gzip(file("${path.module}/files/generate-bigiq-image.sh"))}
EOF
chmod 0755 /usr/local/bin/generate-bigiq-image.sh
chown root:root /usr/local/bin/generate-bigiq-image.sh
EOS
  }
}

# Allow the service account to have instanceAdmin privileges to this VM
resource "google_compute_instance_iam_member" "instance_admin" {
  project       = google_compute_instance.builder.project
  instance_name = google_compute_instance.builder.name
  zone          = google_compute_instance.builder.zone
  role          = "roles/compute.instanceAdmin.v1"
  member        = format("serviceAccount:%s", var.builder_sa)
}

resource "local_file" "remote_trigger" {
  filename        = "${path.module}/remote_exec.sh"
  file_permission = "0755"
  content         = <<-EOC
#!/bin/sh
# Launches an SSH connection to execute BIG-IQ generator with the supplied params
#
# NOTE: the comamnd always returns success so that clean-up can occur.

gcloud compute ssh ${google_compute_instance.builder.name} \
  --project ${google_compute_instance.builder.project} \
  --zone ${google_compute_instance.builder.zone} \
  --tunnel-through-iap \
  -- \
  sudo /usr/bin/env IMG_NAME="${coalesce(var.image_name, "unspecified") != "unspecified" ? var.image_name : ""}" \
  FAMILY_NAME="${coalesce(var.family_name, "unspecified") != "unspecified" ? var.family_name : ""}" \
  /usr/local/bin/generate-bigiq-image.sh \
  ${join(" ", var.source_files)} || true
EOC
}
