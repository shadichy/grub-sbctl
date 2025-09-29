#!/bin/bash

set -euo pipefail

# Ensure the script is run as root
if [ $EUID != 0 ]; then
	echo "Insufficient permission!"
	echo "Please run this script as root"
	exit 1
fi

# Source configuration file(s)
# shellcheck disable=SC1091
if [ -f /etc/gsb.conf ]; then
	source /etc/gsb.conf
	if [ -f /etc/gsb.user.conf ]; then
		source /etc/gsb.user.conf
	fi
else
	source gsb.conf # For debugging purposes
fi

while [ $# -gt 0 ]; do
	case $1 in
	--install-sbctl) INSTALL_SBCTL=true ;;
	--grub-keydir) GRUB_KEYDIR=$2 && shift ;;
	--bootloader-path) BL_PATH=$2 && shift ;;
	--grub-confdir) GRUB_CONFDIR=$2 && shift ;;
	--grub-modules) GRUB_MODULES=$2 && shift ;;
	--grub-bootloader-id) BL_ID=$2 && shift ;;
	--target) TARGET=$2 && shift ;;
	--write-config) CONFIG_OVERRIDE=true ;;
	--help | -h)
		cat <<EOF
Usage: $0 [OPTIONS]

Options:  
  --install-sbctl           Install sbctl SecureBoot key if not already installed
  --grub-keydir PATH        Directory to store GRUB gpg keys
  --bootloader-path PATH    Path to the EFI System Partition's bootloader
  --grub-confdir PATH       Directory for GRUB configuration files (where grub.cfg is located)
  --grub-modules MODULES    GRUB modules to include
  --grub-bootloader-id ID   GRUB bootloader ID (default: auto-detected)
  --target TARGET           Target architecture (i386, x86_64, arm, arm64; default: auto-detected)
  --write-config            Write your custom configuration (/etc/gsb.user.conf)
  --help                    Show this help message and exit

Default values for GRUB keydir, confdir and modules are specified in /etc/gsb.conf.
EOF
		exit 0
		;;
	*) echo "Unknown option: $1" && exit 1 ;;
	esac
	shift
done

# Create gpg key for signing GRUB files to prevent security prohibitions
# shellcheck disable=SC2174
mkdir --mode 0700 -p "$GRUB_KEYDIR"
gpg --homedir "$GRUB_KEYDIR" --gen-key
gpg --homedir "$GRUB_KEYDIR" --export >"$GRUB_KEYDIR/boot.key"

if [ ! "$TARGET" ]; then
	TARGET=$(uname -m)
	case "$TARGET" in
	i?86 | x86) TARGET="i386" ;;
	aarch64 | arm64) TARGET="arm64" ;;
	arm*) TARGET="arm" ;;
	esac
fi

if [ ! "$BL_ID" ]; then
	BL_ID=$(basename "$(dirname "$(find "$BL_PATH" -mindepth 2 -maxdepth 2 -type f -iname "grub*.efi" | head -1)")")
fi

if [ "$CONFIG_OVERRIDE" = true ]; then
	cat <<EOF >/etc/gsb.user.conf
GRUB_KEYDIR="$GRUB_KEYDIR"
BL_PATH="$BL_PATH"
GRUB_CONFDIR="$GRUB_CONFDIR"
GRUB_MODULES="$GRUB_MODULES"
BL_ID="$BL_ID"
TARGET="$TARGET"
EOF
fi

if [ "$INSTALL_SBCTL" = true ]; then
	if ! { sbctl status | grep -Eq 'Setup Mode:.+Enabled'; }; then
		echo "Setup Mode is not enabled! Cannot proceed with sbctl key installation."
		exit 1
	fi

	# Create sbctl keys, skip if key creted
	sbctl create-keys || :

	# Enroll keys in the system firmware
	sbctl enroll-keys -fma
fi

grub-install \
	--target="${TARGET}-efi" \
	--efi-directory="$(dirname "$BL_PATH")" \
	--bootloader-id="$BL_ID" \
	--boot-directory="$(dirname "$GRUB_CONFDIR")" \
	--force \
	--modules="$GRUB_MODULES" \
	--pubkey="$GRUB_KEYDIR/boot.key" \
	--sbat=/usr/share/grub/sbat.csv \
	--no-nvram \
	--disable-shim-lock

# Sign GRUB files and modules
grub-sbctl-sign
