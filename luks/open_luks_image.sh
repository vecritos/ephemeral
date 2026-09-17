#!/usr/bin/env bash
set -euo pipefail

# Opens an existing .pac LUKS image and mounts the ext4 filesystem
# at a requested directory path.

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

if ! command -v cryptsetup >/dev/null 2>&1; then
    echo "cryptsetup is required." >&2
    exit 1
fi

read -rp "Enter the path to the .pac image file: " IMAGE_PATH
if [[ ! -f "$IMAGE_PATH" ]]; then
    echo "Image file not found: $IMAGE_PATH" >&2
    exit 1
fi

read -rp "Enter mount path (e.g. /mnt/secure-data): " MOUNT_PATH
mkdir -p "$MOUNT_PATH"

LOOP_DEVICE="$(losetup --find --show "$IMAGE_PATH")"
cleanup() {
    if [[ -n "${LOOP_DEVICE:-}" ]] && losetup -j "$IMAGE_PATH" | grep -q "$LOOP_DEVICE"; then
        umount "$MOUNT_PATH" 2>/dev/null || true
        cryptsetup close luks_pac 2>/dev/null || true
        losetup -d "$LOOP_DEVICE" 2>/dev/null || true
    fi
}
trap cleanup EXIT

read -rp "Enter the LUKS passphrase: " -s PASSPHRASE
printf '\n'

printf '%s' "$PASSPHRASE" | cryptsetup open --type luks2 "$LOOP_DEVICE" luks_pac -
mount /dev/mapper/luks_pac "$MOUNT_PATH"

printf '\nMounted %s at %s\n' "$IMAGE_PATH" "$MOUNT_PATH"
printf 'Filesystem: ext4\n'
