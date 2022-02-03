#!/bin/sh
#
# Script to create a bootable GCE disk image from an official F5 QCOW2 download.
#
# The script is meant to be safely re-entrant as much as possible so it can be
# used interactively for testing.

LOCAL_CACHE=${LOCAL_CACHE:-/tmp/cache}
BOOT_MNT=${BOOT_MNT:-/mnt/boot}
ROOT_MNT=${ROOT_MNT:-/mnt/root}
RPM_DIR="${ROOT_MNT}/tmp/rpms"

# Write an error message to stderr and exit, attempting to unmount BIG-IQ volumes
error()
{
    echo "$0: ERROR: $*" >&2
    umount_targets
    exit 1
}

# Write a message to stderr
info()
{
    echo "$0: INFO: $*" >&2
}

# Unmount devmapper partitions and clean up LVM.
# NOTE: This function will not raise an error if clean up fails as it may be
# part of exit handling.
umount_targets()
{
    while read -r d; do
        mount 2>/dev/null | grep -Eq "^${d}\s+" || continue
        umount "${d}" || info "Failed to umount ${d}; exit code $?"
    done <<EOF
/dev/mapper/vg--db--vda-set.1._config
/dev/mapper/vg--db--vda-dat.share.1
/dev/mapper/vg--db--vda-dat.log.1
/dev/mapper/vg--db--vda-set.1._var
/dev/mapper/vg--db--vda-set.1._usr
/dev/mapper/vg--db--vda-set.1.root
/dev/sdb1
EOF
    if command -v vgchange > /dev/null && command -v dmsetup > /dev/null && command -v pvscan > /dev/null; then
        vgchange -an vg-db-vda || true
        dmsetup ls | awk '/vg--db--vda/ {print $1}' | xargs -rn 1 dmsetup remove || \
            info "Failed to remove stale device-mapper entries"
        pvscan --cache || info "Failed to reset PV cache; exit code $?"
    fi
}

# Quick sanity check - if any BIG-IQ volumes are still mounted return 1 (false)
verify_targets_unmounted()
{
    mount 2>/dev/null | grep -Eq "^/dev/(sdb1|/mapper/vg--db--vda)" && return 1
    return 0
}

# Try to unmount BIG-IQ volumes on ctrl-c, etc.
trap umount_targets INT TERM

[ $(($#)) -gt 0 ] || error "Source files must be provided"

info "Downloading files"
mkdir -p "${LOCAL_CACHE}" || error "Failed to create ${LOCAL_CACHE}; exit code $?"
for f in "$@"; do echo "${f}"; done | gsutil -m cp -n -I "${LOCAL_CACHE}/" || \
    error "Failed to download files from GCS"

BASE_QCOW2="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*\.qcow2(\.zip)?$' | sort -r | head -n 1)"
[ -n "${BASE_QCOW2}" ] || error "Didn't find the base BIG-IQ qcow2 image"
if [ -n "${BASE_QCOW2##*qcow2}" ]; then
    info "Extracting qcow2 from zip"
    unzip -u "${BASE_QCOW2}" -d "${LOCAL_CACHE}/" || \
        error "Failed to unzip ${BASE_QCOW2}; exit code $?"
    BASE_QCOW2="$(find "${LOCAL_CACHE}" -regextype posix-extended -type f -regex '.*\.qcow2$' | sort -r | head -n 1)"
fi
[ -n "${BASE_QCOW2}" ] || error "Didn't find the base BIG-IQ qcow2 image"
BASENAME="$(basename "${BASE_QCOW2}" .qcow2)"

info "Locating target disk"
DISK_NAME="$(curl -sf --retry 20 -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/disks/?recursive=true | jq -r '.[] | select(.index == 1) | .deviceName')"
[ -n "${DISK_NAME}" ] || error "Instance is missing a second disk"
TARGET_DEV="/dev/disk/by-id/google-${DISK_NAME}"
[ -b "${TARGET_DEV}" ] || error "Block device ${TARGET_DEV} is missing"

info "Writing ${BASE_QCOW2} to ${TARGET_DEV}"
qemu-img convert -f qcow2 -O host_device "${BASE_QCOW2}" "${TARGET_DEV}" || \
    error "Failed to copy ${BASE_QCOW2} to ${TARGET_DEV}; exit code $?"

info "Mounting filesystems"
mkdir -p "${BOOT_MNT}" "${ROOT_MNT}" || \
    error "Failed to create mount points ${BOOT_MNT} and/or ${ROOT_MNT}; exit code $?"
pvscan --cache -aay "${TARGET_DEV}" || \
    error "Failed to add PVs, VGs, and LVs from ${TARGET_DEV}; exit code $?"
sleep 2
while read -r d m; do
    mount "${d}" "${m}" || \
        error "Failed to mount ${d} at ${m}; exit code $?"
done <<EOF
${TARGET_DEV}-part1 ${BOOT_MNT}
/dev/vg-db-vda/set.1.root ${ROOT_MNT}
/dev/vg-db-vda/set.1._usr ${ROOT_MNT}/usr
/dev/vg-db-vda/set.1._var ${ROOT_MNT}/var
/dev/vg-db-vda/dat.log.1 ${ROOT_MNT}/var/log
/dev/vg-db-vda/dat.share.1 ${ROOT_MNT}/shared
/dev/vg-db-vda/set.1._config ${ROOT_MNT}/config
EOF

# Change grub.cfg to meet GCP requirements
info "Modifying grub.conf"
sed -E -i -e '/^splashimage/d' \
    -e '/^\s+kernel/s/\s+(console=ttyS?0|quiet|rhgb)//g' \
    -e '/^\s+kernel/s/$/ console=ttyS0,38400n8d/' \
    "${BOOT_MNT}/grub/grub.conf" || error "Failed to update grub.conf; sed exit code $?"

# Extended steps that may be explored in future
if false; then
    # Prepare for cloud use
    touch "${ROOT_MNT}/.vadc_first_boot"
    info "Setting hypervisor type"
    cat <<EOF > "${ROOT_MNT}/shared/vadc/.hypervisor_type"
HYPERVISOR=gce
EOF

    # Disable shell login for root and admin
    info "Disabling shell login for root and admin"
    for user in admin root; do
        chroot "${ROOT_MNT}" /usr/sbin/usermod -L "${user}" || \
            error "Failed to lock ${user}   "
    done

    # Remove existing SSH identities and authorized keys
    info "Cleanup existing SSH files"
    rm -f "${ROOT_MNT}"/root/.ssh/identity*
    [ -f "${ROOT_MNT}/root/.ssh/authorized_keys" ] && : > "${ROOT_MNT}/root/.ssh/authorized_keys"

    # Disable any scheduled fsck
    touch "${ROOT_MNT}/fastboot"
    lvdisplay | awk '/LV Path/ && !/maint|swapvol/ {print $3}' | while read v; do
        tune2fs -i 0 -c 0 ${v} || error "Failed to disable schedule fsck for ${v}"
    done

    # Touch markers
    [ -f "${ROOT_MNT}/etc/.one_slot_marker" ] && touch "${ROOT_MNT}/etc/.one_slot_marker"
    [ -f "${ROOT_MNT}/etc/.all_modules_marker" ] && touch "${ROOT_MNT}/etc/.all_modules_marker"

    # Install any RPMs needed
    if ls "${LOCAL_CACHE}"/*rpm >/dev/null 2>/dev/null; then
        info "Installing RPMs"
        mkdir -p "${RPM_DIR}" || error "Failed to create temporary dir ${RPM_DIR}"
        cp "${LOCAL_CACHE}"/*rpm "${RPM_DIR}/"
        chroot "${ROOT_MNT}" /usr/bin/rpm -iv "${RPM_DIR##"${ROOT_MNT}"}"/*rpm || \
            error "Failed to install RPMs; exit code $?"
        rm -rf "${RPM_DIR}" || error "Failed to remove ${RPM_DIR}; exit code $?"
    fi
fi

info "Unmounting volumes"
sync
umount_targets
verify_targets_unmounted || error "One or more target filesystems are still mounted; exiting"

PROJECT_ID="$(curl -sf -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/project/project-id)"
read -r INSTANCE_NAME INSTANCE_ZONE <<EOF
$(curl -sf -H 'Metadata-Flavor: Google' -H 'Content-Type: application/json' http://169.254.169.254/computeMetadata/v1/instance/?recursive=true | jq -r '[.name, .zone|split("/")[-1]]| join(" ")')
EOF
read -r DISK_ZONE DISK_NAME <<EOF
$(gcloud compute instances describe "${INSTANCE_NAME}" --project "${PROJECT_ID}" --zone "${INSTANCE_ZONE}" --format json | jq -r '.disks[]|select(.index == 1)|.source|split("/")|[.[8], .[10]]| join(" ")')
EOF
info "Creating image from ${DISK_NAME}"
IMG_NAME="${IMG_NAME:-"$(echo "${BASENAME}" | tr -d '\n' | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]_-' '-')-custom"}"
FAMILY_NAME="${FAMILY_NAME:-"$(echo "${IMG_NAME}" |grep -Eo '([a-z]+-)+[0-9]+(-[0-9]+)')"}"
gcloud compute images create "${IMG_NAME}" \
    --source-disk="${DISK_NAME}" \
    --source-disk-zone="${DISK_ZONE}" \
    --description="Custom BIG-IQ image based on $(basename "${BASE_QCOW2}")" \
    --family="${FAMILY_NAME}" \
    --force || \
    error "Failed to create VM image from ${DISK_NAME}; exit code $?"

info "Provisioning complete"
