#!/bin/bash
# Serve ks.cfg over HTTP on the libvirt bridge and build the ESXi ISO that points to it.
# (Embedding KS.CFG in the ISO failed: "cannot find kickstart file on cd-rom".)
# Use systemd-run, NOT pkill -f: a pkill pattern can match and kill your own SSH command.
set -euo pipefail
ISO_IN=/mnt/iso/VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso
mkdir -p ~/ks && cp "$(dirname "$0")/ks.cfg" ~/ks/ks.cfg
sudo systemd-run --unit=ks-http python3 -m http.server 8080 --bind 192.168.122.1 --directory "$HOME/ks"

W=$(mktemp -d); cd "$W"
xorriso -osirrox on -indev "$ISO_IN" -extract /BOOT.CFG boot.cfg
sed 's#kernelopt=runweasel cdromBoot#kernelopt=runweasel ks=http://192.168.122.1:8080/ks.cfg#' boot.cfg > boot_ks.cfg
xorriso -indev "$ISO_IN" -outdev /mnt/iso/esxi-ks.iso -boot_image any replay \
  -map boot_ks.cfg /BOOT.CFG -map boot_ks.cfg /EFI/BOOT/BOOT.CFG -commit
