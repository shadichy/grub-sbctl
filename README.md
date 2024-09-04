# grub-sbctl

This is GRUB setup script to automatically generate GRUB EFI boot files that are capable of booting with SecureBoot

It contains auto-signing GPG key script and a config file

## Install

### Arch Linux

```sh
yay -S grub-secureboot-scripts
# or
paru -S grub-secureboot-scripts
# or
pamac install grub-secureboot-scripts
# or any aur helper you got
```

## Configuration

These are configurations of grub-secureboot-scripts in `/etc/gsb.conf`

Default values are in file `gsb.conf`

### BL_PATH

This is where any bootloader gets installed into your PC.
It's the path where the scripts looks for grub*.efi to sign.
Only change it when your EFI partition is not mounted to /boot/efi by default.
(It will be passed to `--efi-directory` argument of `grub-install`)

```sh
BL_PATH=/boot/efi/efi
```

### GRUB_CONFDIR

This is the path where grub stores its generated boot-required files, modules, themes and configurations.
(It will be passed to `--boot-directory` argument of `grub-install`)

```sh
GRUB_CONFDIR=/boot/grub
```

### GRUB_KEYDIR

This is the path where the program store the generated GPG keys used for auto-signing GRUB modules and configurations.

```sh
GRUB_KEYDIR=/usr/share/grub/sbctl/keys
```

### GRUB_MODULES

This is used to specify the modules that GRUB should be packed with during installation.
These modules will be automatically loaded at GRUB bootloader stage.
Do not change it if you don't know what you are doing.

```sh
GRUB_MODULES="all_video boot btrfs chain crypto ext2 gzio linux luks lvm part_gpt part_msdos search xzio zfs zstd"
```

## Build

### Arch Linux
First clone the repository

```sh
git clone https://github.com/shadichy/grub-sbctl
cd ./grub-sbctl
makepkg -si
```
