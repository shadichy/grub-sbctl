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

append_spaces() {
	local text=$1 width=$2
	while [ ${#text} -lt "$width" ]; do
		text="$text "
	done
	RESULT="$text"
}

smart_flag_formatting() {
	# Requires associative array FLAGS with
	# structure: [$index.$flag_name]=$"description"

	# Get terminal width for formatting
	local TERM_WIDTH
	TERM_WIDTH=$(tput cols)

	# Sort flags by index
	local -a keys_unsorted sorted_keys
	keys_unsorted=("${!FLAGS[@]}")
	IFS=$'\n' readarray -t sorted_keys < <(printf '%s\n' "${keys_unsorted[@]}" | sort)

	# Longest flag name length for padding
	local FLAG_WIDTH=0 flag
	for flag in "${keys_unsorted[@]}"; do
		flag=${flag#*.}
		if [ ${#flag} -gt "$FLAG_WIDTH" ]; then
			FLAG_WIDTH=${#flag}
		fi
	done
	# Add 7 for odd length, 8 for even length
	FLAG_WIDTH=$((FLAG_WIDTH + 8 - FLAG_WIDTH % 2))

	# Print flags with word wrapping
	local prefix value text words first_line line_text _line_text
	for flag in "${sorted_keys[@]}"; do
		# First line prefix (flag name)
		flag_value=${flag#*.}
		append_spaces "  --${flag_value//_/-}" $FLAG_WIDTH
		prefix=$RESULT

		# Flag description
		value=${FLAGS[$flag]}

		text="$RESULT${FLAGS[$flag]}"
		if [ ${#text} -le $((TERM_WIDTH - 2)) ]; then
			printf '%s\n' "$text"
			continue
		fi

		# Word splitting
		words=($value)

		first_line=true
		while [ ${#words[@]} -gt 0 ]; do
			line_text=""

			# Append words until line is full
			while [ ${#words[@]} -gt 0 ]; do
				_line_text="$line_text ${words[0]}"
				if [ ${#_line_text} -gt $((TERM_WIDTH - FLAG_WIDTH - 2)) ]; then
					break
				fi
				line_text=$_line_text
				words=("${words[@]:1}")
			done

			printf '%s%s\n' "$prefix" "${line_text#* }"

			# For subsequent lines, use spaces as prefix
			if $first_line; then
				append_spaces " " $FLAG_WIDTH
				prefix=$RESULT
				first_line=false
			fi
		done
	done
}

# Verbose flags
STDOUT=/dev/null
SBCTL_VERBOSE='--quiet'
GRUB_VERBOSE=''
GPG_VERBOSE='-q'

while [ $# -gt 0 ]; do
	case $1 in
	--install-sbctl) INSTALL_SBCTL=true ;;
	--grub-keydir) GRUB_KEYDIR=$2 && shift ;;
	--bootloader-path) BL_PATH=$2 && shift ;;
	--grub-confdir) GRUB_CONFDIR=$2 && shift ;;
	--grub-modules) GRUB_MODULES=$2 && shift ;;
	--grub-bootloader-id) BL_ID=$2 && shift ;;
	--target) TARGET=$2 && shift ;;
	--dry-run) DRY_RUN=true ;;
	--write-config) CONFIG_OVERRIDE=true ;;
	--verbose | -v) STDOUT=/dev/stdout && SBCTL_VERBOSE='--debug' && GRUB_VERBOSE='-v' && GPG_VERBOSE='-v' ;;
	--help | -h)

		# Flags and descriptions
		declare -A FLAGS
		FLAGS=(
			[0.install_sbctl]="Install sbctl SecureBoot keys if not already installed."
			[1.bootloader_path]="Path to the EFI System Partition's bootloader."
			[2.grub_keydir]="Directory to store GRUB gpg keys."
			[3.grub_confdir]="Directory for GRUB configuration files (where grub.cfg is located)."
			[4.grub_bootloader_id]="GRUB bootloader ID (default: auto-detected)."
			[5.grub_modules]="GRUB modules to include."
			[6.target]="Target architecture (i386, x86_64, arm, arm64; default: auto-detected)."
			[7.dry_run]="Perform a dry run without making any changes except for user configuration."
			[8.write_config]="Write your custom configuration (/etc/gsb.user.conf). Run with --dry-run to prevent overriding bootloader."
			[9.verbose]="Enable verbose output."
			[10.help]="Show this help message and exit"
		)

		cat <<EOF
Usage: $0 [OPTIONS]

Options:
$(smart_flag_formatting)

Default values for GRUB keydir, confdir and modules are specified in /etc/gsb.conf.
EOF
		exit 0
		;;
	*) echo "Unknown option: $1" && exit 1 ;;
	esac
	shift
done

# PATH for debugging
if [ "$GRUB_VERBOSE" ]; then
	export PATH=$(pwd):$PATH
fi

main() {
	# Autodetect architecture if not specified
	if [ ! "${TARGET:=}" ]; then
		TARGET=$(uname -m)
		case "$TARGET" in
		i?86 | x86) TARGET="i386" ;;
		aarch64 | arm64) TARGET="arm64" ;;
		arm*) TARGET="arm" ;;
		esac
	fi

	# Autodetect bootloader id if not specified
	if [ ! "${BL_ID:=}" ]; then
		BL_ID=$(basename "$(dirname "$(find "$BL_PATH" -mindepth 2 -maxdepth 2 -type f -iname "grub*.efi" | head -1)")")
	fi

	# Write user configuration
	if "${CONFIG_OVERRIDE:=false}"; then
		cat <<EOF >/etc/gsb.user.conf
GRUB_KEYDIR="$GRUB_KEYDIR"
BL_PATH="$BL_PATH"
GRUB_CONFDIR="$GRUB_CONFDIR"
GRUB_MODULES="$GRUB_MODULES"
BL_ID="$BL_ID"
TARGET="$TARGET"
EOF
	fi

	# Exit if dry run
	if "${DRY_RUN:=false}"; then
		echo "Dry run enabled, exiting before making any changes." >&2
		exit 0
	fi

	# Create gpg key for signing GRUB files to prevent security prohibitions
	# shellcheck disable=SC2174
	if [ ! -f "$GRUB_KEYDIR/boot.key" ]; then
		echo "Creating new local gpg key for GRUB signing..." >&2
		echo "Note: Create a password to enhance security." >&2
		echo "      Leave passwordless (empty) is recommended for convenience." >&2

		# Get machine data for gpg key
		local dmi_id_dir=/sys/devices/virtual/dmi/id product_name product_version product_serial
		product_name=$(<"$dmi_id_dir/product_name")
		product_version=$(<"$dmi_id_dir/product_version")
		product_serial=$(<"$dmi_id_dir/product_serial")

		# Prompt for key password
		local password retyped_password
		read -r -s -p "Password: " password
		echo
		read -r -s -p "Retype Password: " retyped_password
		echo
		if [ "$password" != "$retyped_password" ]; then
			echo "Passwords do not match!" >&2
			exit 1
		fi

		# Generate gpg key non-interactively
		mkdir --mode 0700 -p "$GRUB_KEYDIR"
		gpg $GPG_VERBOSE --homedir "$GRUB_KEYDIR" --gen-key --batch <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $product_name
Name-Comment: $product_version
Name-Email: $product_serial@$(hostname).localdomain
Expire-Date: 0
Passphrase: $password
%no-protection
%commit
EOF
		gpg $GPG_VERBOSE --homedir "$GRUB_KEYDIR" --export >"$GRUB_KEYDIR/boot.key"
	fi

	# Install sbctl keys if requested
	if [ "$INSTALL_SBCTL" = true ]; then
		if ! { sbctl status | grep -Eq 'Setup Mode:.+Enabled'; }; then
			echo "Setup Mode is not enabled! Cannot proceed with sbctl key installation." >&2
			echo "Go to your BIOS/uEFI firmware settings, disable SecureBoot and enable Setup Mode (some brands require wiping current SecureBoot keys)." >&2
			exit 1
		fi

		# Create sbctl keys, skip if key created
		sbctl $SBCTL_VERBOSE create-keys || :

		# Enroll keys in the system firmware
		sbctl $SBCTL_VERBOSE enroll-keys -ma
	fi

	# (Re)install GRUB bootloader
	grub-install \
		$GRUB_VERBOSE \
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
	# Output must be shown regardless of verbosity level
	grub-sbctl-sign >&2

	echo "Setup completed." >&2
}

main >$STDOUT
