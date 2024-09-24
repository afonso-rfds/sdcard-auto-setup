#!/usr/bin/env bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please use 'sudo' or log in as the root user."
  exit 1
fi

# Script exits on error or when it encounters undefined variables
set -eu

# Parameters
DISK=${1:-/dev/sdb}
BOOT_FILES_DIR=${2:-/home/workspace/BootFiles}
RFS_FILE=${3:-rfs.ui}
BOOT_SIZE=${4:-1G}
ROOTFS_SIZE=${5:-1G}

# Temporary files
SD_IMG=$(mktemp sd.img.XXXXXX)
MBR_IMG=$(mktemp mbr.img.XXXXXX)

# Cleanup on exit or interrupt
trap 'cleanup' EXIT
cleanup() {
  if mountpoint -q /mnt; then
    umount /mnt
  fi
  rm -f $SD_IMG $MBR_IMG
}

# Verify if the disk exists
if [[ ! -b $DISK ]]; then
  echo "Error: $DISK is not a valid block device."
  exit 1
fi

# Calculate the block device size in MB
CARD_TOTAL_SIZE=$(blockdev --getsize64 $DISK)
BLOCK_DEVICE_SIZE_MB=$((CARD_TOTAL_SIZE / 1048576))


# Erase SD Card
sgdisk --zap-all $DISK

# Populate SD_IMG with zeros
dd if=/dev/zero of=$SD_IMG bs=1M count=$BLOCK_DEVICE_SIZE_MB conv=sparse

# Create MBR Partition Table
echo -e "o\nw" | fdisk $SD_IMG

# Create "boot" FAT partition of BOOT_SIZE size
echo -e "n\np\n1\n2048\n+${BOOT_SIZE}\nt\nc\nw" | fdisk $SD_IMG

# Create "qnxrootfs" qnx6 partition of ROOTFS_SIZE size
echo -e "n\np\n2\n\n+${ROOTFS_SIZE}\nt\n2\nb3\nw" | fdisk $SD_IMG

# Create MBR Image
dd if=$SD_IMG bs=512 count=1 of=$MBR_IMG

# Deploy MBR Image to SD Card
dd if=$MBR_IMG of=$DISK status=progress

# Format first partition to a FAT Partition
mkfs.vfat -F 32 -n boot ${DISK}1

# Create mount point and copy files to IFS partition
mount ${DISK}1 /mnt
cp ${BOOT_FILES_DIR}/ifs-xilinx-versal-te0950.ui /mnt/
cp ${BOOT_FILES_DIR}/boot.bin /mnt/
echo "Files in FAT Partition: "
ls /mnt
umount /mnt

# Flash RFS Partition
dd if=$RFS_FILE of=${DISK}2 status=progress

echo "Command finished successfully!"