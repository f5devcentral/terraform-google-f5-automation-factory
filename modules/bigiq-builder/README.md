# BIG-IQ image builder for Google Cloud

This Terraform module will create a Compute Engine VM that can be used to generate
a BIG-IQ Compute Engine image from an official F5 KVM qcow2 download.

> NOTE: See also [BIG-IQ trigger](/modules/triggers/big-iq) module for an automated

## Usage

### Prerequisites

F5 BIG-IQ images are available to download by registered customers; you will need
to retrieve the official image and place it in a location where a GCP VM can
access it - a GCS bucket is a good choice.

1. Download BIG-IQ KVM qcow2 image from F5

    1. Register if necessary, and login to [downloads.f5.com](https://downloads.f5.com)

    2. Click **Find a Download** button

    3. Click BIG-IQ [Centralized Management](https://downloads.f5.com/esd/product.jsp?sw=BIG-IQ&pro=big-iq_CM) link

    4. Click the link for the Virtual Edition version you want; e.g. `8.1.0.2_Virtual-Edition`

    5. Download the BIG-IQ qcow2 (or .qcow2.zip) file, but **NOT** the ***LARGE*** image; e.g. `BIG-IQ-8.1.0.2-0.0.36.qcow2` or
    `BIG-IQ-8.1.0.2-0.0.36.qcow2.zip` are valid, but `BIG-IQ-8.1.0.2-0.0.36.LARGE.qcow2` is not suitable

    6. Optional, but recommended: verify downloaded image integrity
        1. Download `archive.pubkey.20220812.pem` and the corresponding `.384.sig.`
           file for your download

        2. Verify the downloaded image; e.g. to verify `BIG-IQ-8.1.0.2-0.0.36.qcow2.zip`

            ```shell
            openssl dgst -sha384 -verify archive.pubkey.20220812.pem \
                -signature BIG-IQ-8.1.0.2-0.0.36.qcow2.zip.384.sig \
                BIG-IQ-8.1.0.2-0.0.36.qcow2.zip
            ```

            *Output:*

            ```text
            Verified OK
            ```

2. Upload the BIG-IQ .qcow2 or .qcow2.zip image to a GCS bucket

    ```shell
    gsutil cp BIG-IQ-8.1.0.2-0.0.36.qcow2.zip gs://my-gcs-bucket/big-iq/
    ```

    *Output:*

    ```text
    Copying file://BIG-IQ-8.1.0.2-0.0.36.qcow2.zip [Content-Type=application/zip]...
    ...

    \ [1 files][  2.6 GiB/  2.6 GiB]  998.1 KiB/s
    Operation completed over 1 objects/2.6 GiB.
    ```

3. Verify that the Compute Engine service account you intend to use has access
   to the uploaded .qcow2/.qcow2.zip file, creating and assigning roles as needed

    > If you want to use the Default Compute service account, use `gcloud` to get
    > it's fully-qualified email identifier and verify it is not disabled
    >
    > ```shell
    > gcloud iam service-accounts list \
    >     --project my-gcp-project \
    >     --filter='email~compute' \
    >     --format='value(email,disabled)'
    > ```
    >
    > *Output:*
    >
    > ```text
    > NNNNNNNNNNNN-compute@developer.gserviceaccount.com    False
    > ```

4. Identify and/or create the VPC subnetwork to which the builder VM will be
   attached

    To retrieve the fully-qualified self-link of a subnet in your project

    ```shell
    gcloud compute networks subnets describe f5-automation-factory-vmbuilder-west1 \
        --format='value(selfLink)' \
        --project my-gcp-project
    ```

    *Output:*

    ```text
    https://www.googleapis.com/compute/v1/projects/my-gcp-project/regions/us-west1/subnetworks/f5-automation-factory-vmbuilder-west1
    ```

### Generating the BIG-IQ image

1. Set the required Terraform variables, either in a `terraform.tfvars` file or
   through a wrapper `main.tf` that consumes this module.

    ```hcl
    project_id         = "my-gcp-project"

    builder_subnetwork = "https://www.googleapis.com/compute/v1/projects/my-gcp-project/regions/us-west1/subnetworks/f5-automation-factory-vmbuilder-west1"

    builder_sa         = "f5-automation-factory-vm-builder@my-gcp-project.iam.gserviceaccount.com"

    source_files       = [
        "gs://my-gcs-bucket/big-iq/BIG-IQ-8.1.0.2-0.0.36.qcow2.zip",
    ]
    ```

2. Execute Terraform

    ```shell
    terraform init
    terraform apply -auto-approve
    ```

    This will create a Compute Engine VM with a secondary disk attached that will
    become the target disk for a BIG-IQ install.

3. Connect to the BIG-IQ builder VM through SSH and execute `generate-bigiq-image.sh`
   script to generate the BIG-IQ Compute Engine image from qcow2 file

    > NOTE: Step 2 has generated a shell script that encapsulates the actions;
    > you should expect the process to take around 20 minutes to complete.

    ```shell
    sh ./remote_exec.sh
    ```

    *Output:*

    ```text
    /usr/local/bin/generate-bigiq-image.sh: INFO: Downloading files
    Copying gs://my-gcs-bucket/big-iq/BIG-IQ-8.1.0.2-0.0.36.qcow2.zip...
    | [1/1 files][  2.6 GiB/  2.6 GiB] 100% Done   5.2 MiB/s ETA 00:00:00
    Operation completed over 1 objects/2.6 GiB.
    /usr/local/bin/generate-bigiq-image.sh: INFO: Extracting qcow2 from zip
    Archive:  /tmp/cache/BIG-IQ-8.1.0.2-0.0.36.qcow2.zip
      inflating: /tmp/cache/BIG-IQ-8.1.0.2-0.0.36.qcow2
    /usr/local/bin/generate-bigiq-image.sh: INFO: Locating target disk
    /usr/local/bin/generate-bigiq-image.sh: INFO: Writing /tmp/cache/BIG-IQ-8.1.0.2-0.0.36.qcow2 to /dev/disk/by-id/google-persistent-disk-1
    /usr/local/bin/generate-bigiq-image.sh: INFO: Mounting filesystems
      8 logical volume(s) in volume group "vg-db-vda" now active
    /usr/local/bin/generate-bigiq-image.sh: INFO: Modifying grub.conf
    /usr/local/bin/generate-bigiq-image.sh: INFO: Unmounting volumes
      0 logical volume(s) in volume group "vg-db-vda" now active
    /usr/local/bin/generate-bigiq-image.sh: INFO: Creating image from f5-automation-factory-seasnail-bigiq-target
    Created [https://www.googleapis.com/compute/v1/projects/my-gcp-project/global/images/big-iq-8-1-0-2-0-0-36-custom].
    WARNING: Some requests generated warnings:
    -

    NAME                          PROJECT         FAMILY      DEPRECATED  STATUS
    big-iq-8-1-0-2-0-0-36-custom  my-gcp-project  big-iq-8-1              READY
    /usr/local/bin/generate-bigiq-image.sh: INFO: Provisioning complete
    Connection to compute.NNNNNNNNNNNN closed.
    ```

4. Verify the BIG-IQ image has been built and is available for use

    ```shell
    gcloud compute images list --project my-gcp-project \
        --filter='selfLink:my-gcp-project' \
        --format='value(creationTimestamp,name)' | sort -nr | head -n 1
    ```

    *Output:*

    ```text
    2022-02-02T20:59:16.267-08:00    big-iq-8-1-0-2-0-0-36-custom
    ```

5. Tear-down the Compute Engine VM

    ```shell
    terraform destroy -auto-approve
    ```

## Module Details

<!-- markdownlint-disable no-inline-html no-bare-urls -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_disk.target](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_instance.builder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance_iam_member.instance_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_iam_member) | resource |
| [local_file.remote_trigger](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_shuffle.zones](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [google_compute_subnetwork.subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_builder_sa"></a> [builder\_sa](#input\_builder\_sa) | The service account email that the builder VM will use. | `string` | n/a | yes |
| <a name="input_builder_subnetwork"></a> [builder\_subnetwork](#input\_builder\_subnetwork) | The fully-qualified subnetwork self-link to use with the VM Builder for BIG-IQ. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project id that will be used to launch an F5 BIG-IQ compute image builder. | `string` | n/a | yes |
| <a name="input_source_files"></a> [source\_files](#input\_source\_files) | The list of GCS source files to drive BIG-IG image creation. | `list(string)` | n/a | yes |
| <a name="input_family_name"></a> [family\_name](#input\_family\_name) | An optional family name to give to the generated BIG-IQ image. | `string` | `null` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | An optional image name to give to the generated BIG-IQ image. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional set of key:value string pairs to assign as labels to resources, in<br>addition to those enforced by the module. | `map(string)` | `{}` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The machine type to use for BIG-IQ image builder. | `string` | `"e2-standard-4"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix to apply to resource names to avoid collisions. | `string` | `"f5-automation-factory"` | no |
| <a name="input_target_size_gb"></a> [target\_size\_gb](#input\_target\_size\_gb) | The size of the target disk for BIG-IQ; default is 120. | `number` | `120` | no |
| <a name="input_tf_service_account"></a> [tf\_service\_account](#input\_tf\_service\_account) | An optional service account email that the Google provider will be configured to<br>impersonate. | `string` | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html no-bare-urls -->
