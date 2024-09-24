# SD Card Partitioning and Formatting Script

This repository contains a Bash script to partition, format, and deploy boot and root filesystems to an SD card. The script is designed for systems that require specific partition layouts, such as a bootable FAT partition and a custom root filesystem. This script automates the process of preparing an SD card for booting embedded devices.

## Features

- Checks for root privileges to ensure the script is run with necessary permissions.
- Configurable parameters for disk device, boot files directory, root filesystem, and partition sizes.
- Creates an **MBR (Master Boot Record) partition table**.
- Automatic partition creation for:
  - A **FAT32** boot partition.
  - A **QNX6** root filesystem partition.
- Deploys a bootloader (`boot.bin`) and other necessary boot files to the FAT32 partition.
- Flashes the root filesystem to the second partition.
- Provides cleanup on exit or script termination.
  
## Script Breakdown

- **Root Check**: Ensures the script is run as root using `$EUID`.
- **Temporary Files**: Uses `mktemp` to create temporary image files for the SD card and MBR.
- **Cleanup**: The `trap` command ensures all resources are properly cleaned up on exit.
- **Disk Partitioning**: The script uses `fdisk` to create an **MBR (Master Boot Record)** partition table with a FAT32 boot partition and a QNX6 root filesystem partition.
- **Formatting**: The first partition is formatted as FAT32 using `mkfs.vfat`.
- **File Deployment**: Boot files are copied to the FAT32 partition, and the root filesystem image is flashed to the second partition using `dd`.

## Usage

1. Run the script with superuser privileges:

    ```bash
    sudo ./sdcard-auto-setup.sh [DISK] [BOOT_FILES_DIR] [RFS_FILE] [BOOT_SIZE] [ROOTFS_SIZE]
    ```

    - `DISK`: The block device for the SD card (default: `/dev/sdb`).
    - `BOOT_FILES_DIR`: Directory containing the boot files (default: `/home/workspace/BootFiles`).
    - `RFS_FILE`: The root filesystem file (default: `rfs.ui`).
    - `BOOT_SIZE`: Size of the boot partition (default: `1G`).
    - `ROOTFS_SIZE`: Size of the root filesystem partition (default: `1G`).

4. Example:

    ```bash
    sudo ./sdcard-auto-setup.sh /dev/sdb /path/to/bootfiles rfs.ui 500M 2G
    ```


## Considerations

- Make sure to verify the correct disk device before running the script, as this script will erase the target SD card completely.
- You can modify the default parameters (like partition sizes and boot file paths) by editing the script or providing them as arguments.

