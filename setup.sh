#!/bin/bash

if [ $EUID != 0 ]; then
	echo "Insufficient permission!"
	exit 1
fi

if { sbctl status | grep -E 'Setup Mode:.+Enabled'; }; then
	echo "Setup Mode is not enabled!"
	exit 1
fi

# shellcheck disable=SC1091
source /etc/gsb.conf

mkdir --mode 0700 "$GRUB_KEYDIR"
gpg --homedir "$GRUB_KEYDIR" --gen-key
gpg --homedir "$GRUB_KEYDIR" --export >"$GRUB_KEYDIR/boot.key"

target=$(uname -r)
case "$target" in
i?86 | x86) target="i386" ;;
aarch64 | arm64) target="arm64" ;;
arm*) target="arm" ;;
esac

bl_id=$(basename "$(dirname "$(find "$BL_PATH" -mindepth 2 -maxdepth 2 -type f -iname "grub*.efi" | head -1)")")

grub-install \
	--target="${target}-efi" \
	--efi-directory="$(dirname "$BL_PATH")" \
	--bootloader-id="$bl_id" \
	--boot-directory="$GRUB_CONFDIR" \
	--force \
	--modules="$GRUB_MODULES" \
	--pubkey="$GRUB_KEYDIR/boot.key" \
	--sbat=/usr/share/grub/sbat.csv \
	--no-nvram \
	--disable-shim-lock &&
	grub-sbctl-sign || exit 1
