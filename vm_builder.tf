locals {
  vmbuilder_sa_email  = format("%s-vm-builder@%s.iam.gserviceaccount.com", var.prefix, var.project_id)
  vmbuilder_sa_iam_id = format("serviceAccount:%s", local.vmbuilder_sa_email)
}

# Create a service account for VM builder modules
module "vmbuilder_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.0"
  project_id = var.project_id
  prefix     = var.prefix
  names      = ["vm-builder"]
  descriptions = [
    "VM builder service account for F5 Automation Factory",
  ]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer",
    "${var.project_id}=>roles/compute.storageAdmin",
  ]
  generate_keys = false
}

locals {
  subnet_offset = var.vmbuilders.subnet_size - tonumber(split("/", var.vmbuilders.vpc_cidr)[1])
}

# Create a network for builder VMs
module "vmbuilder_vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "4.1.0"
  project_id                             = var.project_id
  network_name                           = format("%s-vmbuilder", var.prefix)
  description                            = format("VPC network for VM builders (%s)", var.prefix)
  delete_default_internet_gateway_routes = false
  subnets = [for index, region in var.vmbuilders.regions : {
    subnet_name           = replace(region, "/^[^-]+/", format("%s-vmbuilder", var.prefix))
    subnet_ip             = cidrsubnet(var.vmbuilders.vpc_cidr, local.subnet_offset, index)
    subnet_region         = region
    subnet_private_access = false
  }]
}

resource "google_compute_firewall" "iap" {
  project   = var.project_id
  name      = format("%s-iap-vmbuilder", var.prefix)
  network   = module.vmbuilder_vpc.network_self_link
  direction = "INGRESS"
  source_ranges = [
    "35.235.240.0/20",
  ]
  target_service_accounts = [
    local.vmbuilder_sa_email
  ]

  allow {
    protocol = "TCP"
    ports = [
      22,
    ]
  }

  depends_on = [
    module.vmbuilder_sa,
    module.vmbuilder_vpc,
  ]
}
