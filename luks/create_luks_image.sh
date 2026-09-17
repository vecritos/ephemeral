#!/usr/bin/env bash
set -euo pipefail

# Creates a new encrypted .pac file image of a requested size,
# formats it with LUKS and ext4, and leaves it closed.

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

if ! command -v cryptsetup >/dev/null 2>&1; then
    echo "cryptsetup is required." >&2
    exit 1
fi

read -rp "Enter the path for the .pac image file (e.g. /srv/secure-data.pac): " IMAGE_PATH
read -rp "Enter size in GB to create: " SIZE_GB

if ! [[ "$SIZE_GB" =~ ^[1-9][0-9]*$ ]]; then
    echo "Size must be a positive integer number of GB." >&2
    exit 1
fi

if [[ -e "$IMAGE_PATH" ]]; then
    echo "File already exists: $IMAGE_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$IMAGE_PATH")"
SIZE_BYTES=$(( SIZE_GB * 1024 * 1024 * 1024 ))

truncate -s "$SIZE_BYTES" "$IMAGE_PATH"

LOOP_DEVICE="$(losetup --find --show "$IMAGE_PATH")"
cleanup() {
    if [[ -n "${LOOP_DEVICE:-}" ]] && losetup -j "$IMAGE_PATH" | grep -q "$LOOP_DEVICE"; then
        cryptsetup close "luks_pac" 2>/dev/null || true
        losetup -d "$LOOP_DEVICE" 2>/dev/null || true
    fi
}
trap cleanup EXIT

read -rp "Enter a LUKS passphrase for this image: " -s PASSPHRASE
printf '\n'

printf '%s' "$PASSPHRASE" | cryptsetup luksFormat --type luks2 --batch-mode "$LOOP_DEVICE" -

printf '%s' "$PASSPHRASE" | cryptsetup open --type luks2 "$LOOP_DEVICE" luks_pac -

mkfs.ext4 -F /dev/mapper/luks_pac

cryptsetup close luks_pac
losetup -d "$LOOP_DEVICE"
trap - EXIT

printf '\nCreated encrypted ext4 image at %s\n' "$IMAGE_PATH"
printf 'Size: %s GB\n' "$SIZE_GB"
printf 'It is currently closed and ready to be opened with the mount script.\n'
